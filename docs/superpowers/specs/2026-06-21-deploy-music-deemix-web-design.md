# Déploiement de `music` (deemix-web) sur hizuru — Design

**Date** : 2026-06-21
**Auteur** : titosy (avec Claude en mode prof)
**Cible** : VPS `hizuru` (94.250.201.16), géré par le repo `remote-os` (NixOS + colmena)
**App** : https://github.com/titoo-dev/music — Next.js, image GHCR `ghcr.io/titoo-dev/deemix-web` (publique)

## 1. Objectif

Faire tourner l'application `deemix-web` (web de téléchargement/streaming musical) pour
l'utilisateur `titosy`, sur le serveur partagé avec `ony`, de façon **déclarative et
reproductible**, derrière le reverse proxy Caddy existant, en HTTPS sur
**`music.titosy.dev`**.

Remplace l'ancien workflow Dokploy de titosy : mêmes images Docker (GHCR), mais pilotées
par NixOS (`virtualisation.oci-containers`) au lieu d'un PaaS impératif.

## 2. Périmètre

### Dans la v1
- `web` : l'app Next.js (`ghcr.io/titoo-dev/deemix-web`), port interne 3000.
- `postgres` : base de données (`postgres:17-alpine`).
- `redis` : file BullMQ (`redis:7-alpine`, `--appendonly yes --maxmemory-policy noeviction`).
- `minio` : stockage objet S3 (`minio/minio`) + création du bucket `deemix-music`.
- Reverse proxy Caddy → `music.titosy.dev` (HTTPS automatique).
- Secrets via agenix (1er secret de titosy).

### Hors v1 (différé, justifié)
- **`stems-worker`** (séparation audio par IA) : 8 Go RAM / 4 CPU, trop lourd sur un VPS
  **partagé avec ony**, et **son image n'est pas publiée sur GHCR** (buildée depuis les
  sources). À ajouter plus tard si besoin, après avoir publié son image.
- **Backups automatisés** de Postgres/MinIO : à ajouter dans une itération ultérieure.
- **Console MinIO publique** : non exposée (accès admin par tunnel SSH si besoin).

## 3. Architecture

Tous les services tournent en conteneurs Docker (backend déjà activé via
`defaults/services/docker.nix`), sur un **réseau Docker dédié `music`**. Les conteneurs se
joignent au réseau avec des **alias** correspondant aux noms d'hôtes que l'app attend
(`postgres`, `redis`, `minio`), pour que les URLs `postgresql://…@postgres:5432` et
`redis://redis:6379` résolvent sans modification de l'app.

```
Internet ──443──> Caddy (hôte) ──> 127.0.0.1:3000 ──> [music-web]
                                                          │  réseau docker "music"
                              [music-postgres] <─────────┤  (alias: postgres)
                              [music-redis]    <─────────┤  (alias: redis)
                              [music-minio]    <─────────┘  (alias: minio)
```

### Ports (exposés sur l'hôte)
- `music-web` : `127.0.0.1:3000` (uniquement pour Caddy).
- `music-postgres` : `127.0.0.1:15432:5432` (uniquement pour le bootstrap des migrations ; pas public).
- `music-redis`, `music-minio` : **non exposés** sur l'hôte (accès interne au réseau docker seul).
- Pare-feu : inchangé — seuls 22/80/443 restent ouverts publiquement.

### Persistance (bind mounts sur l'hôte, créés via `systemd.tmpfiles`)
- `/var/lib/music/postgres` → `/var/lib/postgresql/data`
- `/var/lib/music/redis` → `/data`
- `/var/lib/music/minio` → `/data`

(Bind mounts plutôt que volumes Docker anonymes : les données sont visibles et
sauvegardables depuis l'hôte.)

### Réseau & ordre de démarrage
- Un service systemd oneshot `init-music-network` crée le réseau `music` (idempotent) avant
  les conteneurs.
- Un oneshot `music-createbucket` (image `minio/mc`) crée le bucket `deemix-music` une fois
  MinIO démarré.
- `music-web` démarre après postgres + redis (`dependsOn`).

## 4. Secrets (agenix)

Un secret unique chiffré = le fichier `.env` complet de l'app, monté via `environmentFiles`
dans les conteneurs qui en ont besoin. Mirroir du `env_file: .env` du docker-compose.

- Fichier : `host/hizuru/users/titosy/secrets/music.age`
- Règles : `host/hizuru/users/titosy/secrets/secrets.nix`
  - destinataires = clé d'hôte (`../../../secrets/keys.nix`) + clés de titosy.
  - **Pré-requis** : ajouter une entrée `titosy` (clés ony@…/titosy@…) dans `keys.nix` ou
    localement, pour que titosy puisse éditer le secret avec `agenix -e music.age`.

Contenu de `music.age` (clé=valeur) :

| Variable | Sensible | Valeur |
|---|---|---|
| `DATABASE_URL` | ✅ (contient le mot de passe) | `postgresql://deemix:<pw>@postgres:5432/deemix` |
| `POSTGRES_USER` | non | `deemix` |
| `POSTGRES_PASSWORD` | ✅ | aléatoire |
| `POSTGRES_DB` | non | `deemix` |
| `REDIS_URL` | non | `redis://redis:6379` |
| `BETTER_AUTH_SECRET` | ✅ | `openssl rand -base64 48` |
| `BETTER_AUTH_URL` | non | `https://music.titosy.dev` |
| `GOOGLE_CLIENT_ID` | ✅ | fourni par titosy |
| `GOOGLE_CLIENT_SECRET` | ✅ | fourni par titosy (**à rotater après setup**) |
| `DEEMIX_STORAGE_TYPE` | non | `s3` |
| `DEEMIX_S3_ENDPOINT` | non | `http://minio:9000` |
| `DEEMIX_S3_REGION` | non | `us-east-1` |
| `DEEMIX_S3_BUCKET` | non | `deemix-music` |
| `DEEMIX_S3_ACCESS_KEY` | ✅ | = `MINIO_ROOT_USER` |
| `DEEMIX_S3_SECRET_KEY` | ✅ | = `MINIO_ROOT_PASSWORD` |
| `MINIO_ROOT_USER` | ✅ | identifiant MinIO |
| `MINIO_ROOT_PASSWORD` | ✅ | mot de passe MinIO |
| `MINIO_BUCKET` | non | `deemix-music` |
| `DEEMIX_SERVICE_ARL` | ✅ (optionnel) | ARL Deezer pour le téléchargement |

## 5. Caddy, domaine & DNS

- Vhost : `services.caddy.virtualHosts."music.titosy.dev".extraConfig = "reverse_proxy http://127.0.0.1:3000"`.
- Caddy gère le certificat HTTPS automatiquement, et le **upgrade WebSocket** est
  transparent (pas de config spéciale).
- **Pré-requis manuel (titosy)** : créer un enregistrement **DNS A `music.titosy.dev` →
  94.250.201.16** avant le déploiement, sinon Caddy ne peut pas obtenir le certificat.

## 6. WebSocket : reconstruction de l'image

`NEXT_PUBLIC_WS_URL` est **injecté au build** de l'image (build-arg, depuis la variable de
repo `NEXT_PUBLIC_WS_URL`). L'image publiée embarque donc une URL WS figée.

**Action (titosy)** : régler la variable de repo `NEXT_PUBLIC_WS_URL = wss://music.titosy.dev`
puis relancer le workflow `docker-publish.yml`. On **épinglera le digest** de l'image
résultante (voir §7). Sans ça, la progression temps-réel (téléchargements) risque de ne pas
se connecter.

## 7. Épinglage de l'image (reproductibilité)

L'image `web` est référencée **par digest immuable**, pas par `:latest` :
`ghcr.io/titoo-dev/deemix-web@sha256:…`.

Procédure pour obtenir le digest (après le rebuild §6) :
`docker buildx imagetools inspect ghcr.io/titoo-dev/deemix-web:latest` (ou via l'API du
registre GHCR). « Déployer une nouvelle version » = mettre à jour ce digest dans Git +
`colmena apply`. Postgres/Redis/MinIO restent épinglés par tag officiel (`postgres:17-alpine`,
etc.).

## 8. Migrations Prisma (bootstrap unique)

Le projet utilise **`prisma db push`** (pas de dossier `prisma/migrations/`). L'image
standalone ne contient pas le CLI Prisma, donc le schéma est initialisé **une fois, à la
main** :

```sh
# postgres exposé sur 127.0.0.1:15432, repo music cloné localement
DATABASE_URL='postgresql://deemix:<pw>@127.0.0.1:15432/deemix' npx prisma db push
```

Amélioration future possible : un conteneur oneshot embarquant `schema.prisma` (via input
flake) pour rendre l'init déclarative.

## 9. Fichiers créés / modifiés

```
host/hizuru/users/titosy/
├── default.nix          (modifié : + import ./music.nix)
├── music.nix            (nouveau : réseau + 4 conteneurs + oneshots + vhost Caddy)
└── secrets/
    ├── secrets.nix      (nouveau : règles agenix)
    └── music.age        (nouveau : .env chiffré)
host/hizuru/secrets/keys.nix   (modifié si besoin : ajout des clés de titosy)
```

Esquisse indicative de `music.nix` (détails finalisés à l'implémentation) :

```nix
{ config, pkgs, ... }: let
  webPort = 3000;
in {
  age.secrets.music.file = ./secrets/music.age;

  # Réseau docker dédié
  systemd.services.init-music-network = {
    after = [ "docker.service" ]; requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network inspect music >/dev/null 2>&1 \
        || ${pkgs.docker}/bin/docker network create music
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/music/postgres 0700 999 999 -"
    "d /var/lib/music/redis    0700 999 999 -"
    "d /var/lib/music/minio    0700 root root -"
  ];

  virtualisation.oci-containers.containers = {
    music-postgres = {
      image = "postgres:17-alpine";
      environmentFiles = [ config.age.secrets.music.path ];
      volumes = [ "/var/lib/music/postgres:/var/lib/postgresql/data" ];
      ports = [ "127.0.0.1:15432:5432" ];
      extraOptions = [ "--network=music" "--network-alias=postgres" ];
    };
    music-redis = {
      image = "redis:7-alpine";
      cmd = [ "redis-server" "--appendonly" "yes" "--maxmemory-policy" "noeviction" ];
      volumes = [ "/var/lib/music/redis:/data" ];
      extraOptions = [ "--network=music" "--network-alias=redis" ];
    };
    music-minio = {
      image = "minio/minio:latest";
      cmd = [ "server" "/data" "--console-address" ":9001" ];
      environmentFiles = [ config.age.secrets.music.path ];
      volumes = [ "/var/lib/music/minio:/data" ];
      extraOptions = [ "--network=music" "--network-alias=minio" ];
    };
    music-web = {
      image = "ghcr.io/titoo-dev/deemix-web@sha256:..."; # digest figé (§7)
      environment = { NODE_ENV = "production"; };
      environmentFiles = [ config.age.secrets.music.path ];
      ports = [ "127.0.0.1:${toString webPort}:3000" ];
      dependsOn = [ "music-postgres" "music-redis" "music-minio" ];
      extraOptions = [ "--network=music" ];
    };
  };

  # Création du bucket MinIO (oneshot)
  systemd.services.music-createbucket = { /* mc mb deemix-music */ };

  services.caddy.virtualHosts."music.titosy.dev".extraConfig = ''
    reverse_proxy http://127.0.0.1:${toString webPort}
  '';
}
```

## 10. Étapes manuelles (hors Nix)

1. **DNS** : A `music.titosy.dev` → `94.250.201.16`.
2. **Google OAuth** : ajouter `https://music.titosy.dev/api/auth/callback/google` aux
   *Authorized redirect URIs* (Google Cloud Console).
3. **Rebuild image** avec `NEXT_PUBLIC_WS_URL=wss://music.titosy.dev` (§6).
4. **Récupérer le digest** de l'image et l'épingler dans `music.nix` (§7).
5. **Éditer le secret** `music.age` avec toutes les variables (§4).
6. **Bootstrap DB** : `prisma db push` une fois (§8).
7. **Déployer** : `make` (colmena) ou dry-run d'abord.

## 11. Vérification

- `cd config && nix --accept-flake-config build --dry-run .#colmenaHive.toplevel.hizuru` → plan sans erreur.
- Après déploiement : `https://music.titosy.dev` répond en HTTPS, login Google fonctionne,
  un téléchargement test atterrit dans le bucket MinIO.

## 12. Risques & points de vigilance

- **Ressources** : web+pg+redis+minio sont légers ; OK sur le VPS partagé. (stems exclu pour ça.)
- **Collision de noms** : préfixe `music-*` pour ne pas heurter les conteneurs d'ony (`deemix`, `couchdb`).
- **Secret OAuth exposé en clair** dans le chat → à rotater après validation.
- **WS** : si le rebuild §6 n'est pas fait, la progression temps-réel peut ne pas marcher.
- **UID Postgres** dans les bind mounts : l'image `postgres:17-alpine` tourne en UID 999 ; les
  permissions des dossiers tmpfiles doivent correspondre (à valider à l'implémentation).
