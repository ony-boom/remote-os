# Vaultwarden

Bitwarden-compatible server at `https://vault.ony.world`, configured in
[`config/host/hizuru/users/ony/vaultwarden.nix`](config/host/hizuru/users/ony/vaultwarden.nix).
Any Bitwarden client works: set the server URL to that domain at login.

Public vhost, so the guard is Bitwarden's own login plus `SIGNUPS_ALLOWED = false`.
Accounts are created from `/admin`, which takes the admin password below.
SQLite lives in `/var/lib/vaultwarden`, with a nightly copy in `/var/backup/vaultwarden`.

## Bootstrap

```sh
# 1. One A record -> 94.250.201.16, by hand at the registrar:
#      vault.ony.world
```

`vaultwarden.age` already holds a generated `ADMIN_TOKEN` (argon2) and the
password it hashes, on a comment line:

```sh
cd config/host/hizuru/users/ony/secrets
agenix -d vaultwarden.age
```

To rotate it:

```sh
PW=$(openssl rand -base64 24)
printf %s "$PW" | nix shell nixpkgs#libargon2 -c argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4
echo "$PW"
agenix -e vaultwarden.age        # ADMIN_TOKEN=<hash>, no quoting or $$ escaping
```

```sh
# 2. Deploy, then create the first account at https://vault.ony.world/admin
cd config && make
```
