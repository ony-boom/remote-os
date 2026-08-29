# Garage

[Garage](https://garagehq.deuxfleurs.fr) is the S3-compatible object store on
hizuru, replacing copyparty as the place media lives. Configured in
[`config/host/hizuru/users/ony/garage.nix`](config/host/hizuru/users/ony/garage.nix).

One process, two doors:

| Host              | Port | Component | Auth               | Used by                    |
| ----------------- | ---- | --------- | ------------------ | -------------------------- |
| `s3.ony.world`    | 3900 | `s3_api`  | SigV4, per request | Sveltia CMS, `aws` CLI     |
| `media.ony.world` | 3902 | `s3_web`  | none, GET only     | Browsers loading the site  |

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

Current state: node `895ec1ddffcde3a2`, zone `dc1`, 50G. Key `sveltia-cms`
(`GKfa7ea7b8163058d4a871619b`), read+write on `media`, cannot create buckets.

## Sveltia CMS

The Key ID goes in `static/admin/config.yml` in
[ony.world](https://github.com/ony-boom/ony.world):

```yaml
media_libraries:
  aws_s3:
    endpoint: https://s3.ony.world
    public_url: https://media.ony.world
    bucket: media
    region: garage
    access_key_id: <Key ID>
    acl: false
```

The Secret key is never committed. Paste it in the CMS under **Settings > Media
> Cloud Storage Service API Keys > Amazon S3**. It is not an inline prompt — the
S3 source silently does nothing until the key is saved there. It lives in that
browser's local storage, so it has to be entered again per browser.

Four things that will bite:

- `region` must equal `s3_region` in `garage.nix`. It is part of the SigV4
  credential scope, so drift shows up as a bad signature, not a bad region.
- `acl: false` — Sveltia sends `x-amz-acl: public-read` by default and Garage
  has no ACLs. Public read comes from `bucket website --allow` instead.
- `endpoint` is undocumented on sveltiacms.app but implemented; without it
  Sveltia only ever talks to real AWS.
- Caddy must not rewrite the Host header on `s3.ony.world`. Sveltia signs it.
  Caddy passes it through by default, so just don't add `header_up Host`.

## Rotating the key

Both halves change, and permissions do not carry over.

```sh
sudo garage key delete sveltia-cms
sudo garage key create sveltia-cms
sudo garage bucket allow --read --write media --key sveltia-cms
```

Then update `access_key_id` in `config.yml` (commit, push,
`nix flake update ony-world`, redeploy) and re-paste the secret in the CMS.

Rotation is not needed just to recover a lost secret — unlike AWS, Garage can
show it again:

```sh
sudo garage key info sveltia-cms --show-secret
```

## No web UI

Garage ships only the CLI and a JSON admin API (port 3903, not enabled here).
Third-party UIs exist ([garage-webui](https://github.com/khairul169/garage-webui)
is the usual pick, needs Garage >= 2.0 and the admin API on); an official one is
[funded by NLnet](https://nlnet.nl/project/Garage-AdminUI/) but not shipping yet.
