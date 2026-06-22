# deemix-web (https://github.com/titoo-dev/music) for titosy.
# Stack: web (Next.js) + postgres + redis + minio, on a dedicated docker
# network, fronted by Caddy at https://music.titosy.dev. Secrets via agenix.
{
  config,
  pkgs,
  ...
}: {
  # Decrypt the .env secret to /run/agenix/music at activation. Every container
  # that needs credentials reads it via environmentFiles below.
  age.secrets.music.file = ./secrets/music.age;

  # Dedicated docker network: gives the containers internal DNS so the app can
  # reach its deps by the hostnames it expects (postgres, redis). Idempotent.
  systemd.services.init-music-network = {
    description = "Create the 'music' docker network";
    after = ["docker.service" "docker.socket"];
    requires = ["docker.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker network inspect music >/dev/null 2>&1 \
        || ${pkgs.docker}/bin/docker network create music
    '';
  };

  virtualisation.oci-containers.containers = {
    music-postgres = {
      image = "postgres:17-alpine";
      environmentFiles = [config.age.secrets.music.path];
      volumes = ["/var/lib/music/postgres:/var/lib/postgresql/data"];
      # Exposed on localhost only, for the one-time `prisma db push` bootstrap.
      ports = ["127.0.0.1:15432:5432"];
      extraOptions = ["--network=music" "--network-alias=postgres"];
    };

    music-redis = {
      image = "redis:7-alpine";
      # BullMQ needs noeviction (never drop job keys) + AOF so jobs survive restarts.
      cmd = ["redis-server" "--appendonly" "yes" "--maxmemory-policy" "noeviction"];
      volumes = ["/var/lib/music/redis:/data"];
      extraOptions = ["--network=music" "--network-alias=redis"];
    };

    music-minio = {
      image = "minio/minio:latest";
      cmd = ["server" "/data" "--console-address" ":9001"];
      environmentFiles = [config.age.secrets.music.path];
      volumes = ["/var/lib/music/minio:/data"];
      # S3 API (9000) stays internal — the app reaches it at http://minio:9000.
      # Only the admin console (9001) is bound to localhost (reach via SSH tunnel).
      ports = ["127.0.0.1:9001:9001"];
      extraOptions = ["--network=music" "--network-alias=minio"];
    };

    music-web = {
      # Pinned by immutable digest for reproducibility (image is public).
      image = "ghcr.io/titoo-dev/deemix-web@sha256:28b2053636ee57df4b22a131e9be2a15c8c5536406c14bef2abe991301dd6044";
      environment = {
        NODE_ENV = "production";
        NEXT_TELEMETRY_DISABLED = "1";
      };
      # DATABASE_URL + REDIS_URL (pointing at the docker hostnames) live in the
      # encrypted env, alongside the auth/google/s3 vars.
      environmentFiles = [config.age.secrets.music.path];
      # Host port 3001 — 3000 is already taken by ony's umami. Container stays 3000.
      ports = ["127.0.0.1:3001:3000"];
      dependsOn = ["music-postgres" "music-redis" "music-minio"];
      extraOptions = ["--network=music"];
    };
  };

  # The oci-containers backend generates docker-<name>.service units. Merge extra
  # ordering into them so they wait for the network to exist.
  systemd.services.docker-music-postgres = {
    after = ["init-music-network.service"];
    requires = ["init-music-network.service"];
  };
  systemd.services.docker-music-redis = {
    after = ["init-music-network.service"];
    requires = ["init-music-network.service"];
  };
  systemd.services.docker-music-minio = {
    after = ["init-music-network.service"];
    requires = ["init-music-network.service"];
  };

  # One-shot: create the S3 bucket once MinIO answers. Idempotent (re-runnable).
  systemd.services.music-createbucket = {
    description = "Create the deemix-music bucket in MinIO";
    after = ["docker-music-minio.service"];
    requires = ["docker-music-minio.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.docker}/bin/docker run --rm --network music \
        --env-file ${config.age.secrets.music.path} \
        --entrypoint sh minio/mc -c '
          i=0
          while [ $i -lt 30 ]; do
            mc alias set m http://minio:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" && break
            i=$((i+1)); sleep 2
          done
          mc mb --ignore-existing "m/$MINIO_BUCKET"
        '
    '';
  };

  systemd.services.docker-music-web = {
    after = ["init-music-network.service"];
    requires = ["init-music-network.service"];
  };

  # Public HTTPS entrypoint. Caddy gets/renews the TLS cert automatically and
  # proxies (WebSocket upgrade included) to the web container on localhost.
  services.caddy.virtualHosts."music.titosy.dev".extraConfig = ''
    reverse_proxy http://127.0.0.1:3001
  '';
}
