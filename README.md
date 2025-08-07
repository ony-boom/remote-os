Managing my vps with `nix` and `nixos` is a great way to ensure that my server is reproducible and maintainable. This repository contains the configuration files and scripts necessary to set up and manage my VPS using NixOS.

## Setup

- If using DigitalOcean:

Create a new custom image from the latest NixOS

```sh
nix run .#buildDoImage
```

That will create a `result` directory with the image file.
Import that image into DigitalOcean and create a new droplet with it.

Then inside `./machines`, edit `flake.nix` to add a new machine configuration for your new droplet in the `colmena` section.

- Elsewhere:

Follow the instructions in the [nixos-anywhere repo](https://github.com/nix-community/nixos-anywhere) to install NixOS on the VPS using the `./builder/nixos-anywhere` directory.

### Deployment

Deployemnt is done using [colmena](https://github.com/zhaofengli/colmena).
