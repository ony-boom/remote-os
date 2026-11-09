colmena := "nix --accept-flake-config run .#colmena --"
tofu := "nix shell --inputs-from . nixpkgs#opentofu -c tofu -chdir=builder"

# Deploy to every host
deploy *args:
    {{ colmena }} apply {{ args }}

# Deploy, activate on next boot
boot:
    {{ colmena }} apply boot

# Deploy to this machine
local:
    {{ colmena }} apply-local

fmt:
    nix fmt

check:
    nix flake check

# Create the Contabo hosts in builder/terraform.tfvars and install NixOS on them
provision:
    {{ tofu }} init
    {{ tofu }} apply

# Run any tofu command in builder/
tofu *args:
    {{ tofu }} {{ args }}
