# Self-hosted S3, replaces copyparty.
{
  config,
  pkgs,
  ...
}: let
  s3Port = 3900;
  rpcPort = 3901;
  webPort = 3902;

  cmsOrigin = "https://cms.ony.world";
in {
  age.secrets.garage.file = ./secrets/garage.age;

  services.garage = {
    enable = true;
    package = pkgs.garage_2;
    environmentFile = config.age.secrets.garage.path;

    settings = {
      replication_factor = 1;
      db_engine = "lmdb";

      rpc_bind_addr = "127.0.0.1:${toString rpcPort}";
      rpc_public_addr = "127.0.0.1:${toString rpcPort}";

      s3_api = {
        api_bind_addr = "127.0.0.1:${toString s3Port}";
        # Part of the SigV4 credential scope; must match `region` in
        # ony.world's static/admin/config.yml.
        s3_region = "garage";
      };

      s3_web = {
        bind_addr = "127.0.0.1:${toString webPort}";
        # Bucket name is taken from the host prefix, so media.ony.world -> media.
        root_domain = ".ony.world";
        index = "index.html";
      };
    };
  };

  services.caddy.virtualHosts = {
    # Sveltia CMS uploads from the browser, so the S3 API needs CORS.
    "s3.ony.world".extraConfig = ''
      @preflight method OPTIONS
      handle @preflight {
        header {
          Access-Control-Allow-Origin "${cmsOrigin}"
          Access-Control-Allow-Methods "GET, PUT, HEAD, OPTIONS"
          Access-Control-Allow-Headers "authorization, content-type, x-amz-date, x-amz-content-sha256, x-amz-acl, x-amz-user-agent"
          Access-Control-Max-Age "86400"
        }
        respond 204
      }

      handle {
        header {
          Access-Control-Allow-Origin "${cmsOrigin}"
          Access-Control-Expose-Headers "ETag"
        }
        reverse_proxy http://127.0.0.1:${toString s3Port}
      }
    '';

    "media.ony.world".extraConfig = ''
      encode zstd gzip
      reverse_proxy http://127.0.0.1:${toString webPort}
    '';
  };
}
