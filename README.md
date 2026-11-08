# remote-os

NixOS configuration for my VPS, deployed with [colmena](https://github.com/nix-community/colmena).

## Layout

- `config/defaults`: applied to every host (programs, services, users)
- `config/host/<name>`: one host, with per-user services under `users/<user>`
- `builder`: install media (DigitalOcean image, [nixos-anywhere](https://github.com/nix-community/nixos-anywhere))
- `docs`: notes on individual services

## Commands

Run from `config/`:

```sh
make             # deploy
make boot        # deploy, activate on next boot
nix fmt          # format
nix flake check  # format check, deadnix, statix
```

## Secrets

Encrypted with agenix. Each `secrets/` folder has its own `secrets.nix`, so run
`agenix -e <file>.age` from that folder.

## New host

1. Install NixOS, using `builder/nixos-anywhere` or `nix run .#buildDoImage` from `builder/`.
2. Add it to `colmenaHive` in `config/flake.nix`, with its config in `config/host/<name>`.
