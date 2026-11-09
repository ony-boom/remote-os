# remote-os

NixOS configuration for my VPS, deployed with [colmena](https://github.com/nix-community/colmena).

## Layout

- `defaults`: applied to every host (programs, services, users)
- `host/<name>`: one host, with per-user services under `users/<user>`
- `builder`: OpenTofu config that creates Contabo VPSes and installs NixOS with [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- `docs`: notes on individual services

## Commands

`just` is in `nix develop`.

```sh
just             # deploy
just boot        # deploy, activate on next boot
just fmt         # format
just check       # format check, deadnix, statix
just provision   # create new hosts (see below)
```

## Secrets

Encrypted with agenix. Each `secrets/` folder has its own `secrets.nix`, so run
`agenix -e <file>.age` from that folder.

## New host

1. Add the host to `builder/terraform.tfvars`:

   ```hcl
   hosts = { foo = { product_id = "<id>" } }
   ```

   Product ids are in Contabo's API docs. Then, with the `CNTB_OAUTH2_*`
   Contabo API credentials exported, run `just provision`. This buys the VPS
   and installs a minimal NixOS on it. Removing a host and provisioning again
   cancels it.
2. Add it to `colmenaHive` in `flake.nix`, with its config in `host/<name>`.
