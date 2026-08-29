# Garage

[Garage](https://garagehq.deuxfleurs.fr) is the S3-compatible object store on
hizuru, replacing copyparty as the place media lives. Configured in
[`config/host/hizuru/users/ony/garage.nix`](config/host/hizuru/users/ony/garage.nix).

One process, two doors:

| Host              | Port | Component | Auth               | Used by                   |
| ----------------- | ---- | --------- | ------------------ | ------------------------- |
| `s3.ony.world`    | 3900 | `s3_api`  | SigV4, per request | Sveltia CMS, `aws` CLI    |
| `media.ony.world` | 3902 | `s3_web`  | none, GET only     | Browsers loading the site |

Garage refuses anonymous access on the S3 API, so the web endpoint is the only
way to serve public reads. It takes the bucket from the host prefix
(`s3_web.root_domain = ".ony.world"`), which is why the bucket is named `media`.

Website mode is per bucket, not per object: everything in `media` is public the
moment it lands. Private files need a different bucket.

## Bootstrap

Cluster layout and credentials live in Garage's own metadata store, so none of
this is declarative. Run it once, after the first deploy.

The `garage` CLI is a wrapper that sources the agenix environment file, and that
file is root-only, so every command needs `sudo`.

```sh
# On maki: the RPC secret. Single node, loopback RPC, but Garage won't start
# without it.
cd config/host/hizuru/users/ony/secrets
agenix -e garage.age          # GARAGE_RPC_SECRET=<openssl rand -hex 32>
```

```sh
# On hizuru, after deploying.

# Layout. Node ID comes from `status`; capacity is what you lend the store.
sudo garage status
sudo garage layout assign -z dc1 -c 50G <node-id>
sudo garage layout apply --version 1

# Bucket. `website --allow` is what makes media.ony.world readable.
sudo garage bucket create media
sudo garage bucket website --allow media

# Key. Prints the Key ID and the Secret key together.
sudo garage key create sveltia-cms

# Grant it. A new key has no permissions until this runs.
sudo garage bucket allow --read --write media --key sveltia-cms
```

