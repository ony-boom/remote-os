# agenix rules for titosy's secrets. Run `agenix -e <file>.age` from this folder.
# This file is read ONLY by the agenix CLI to know who to encrypt for — NixOS
# never imports it. Recipients = the host key (so hizuru can decrypt at
# activation) + titosy's personal keys (so titosy can edit the secrets).
let
  inherit (import ../../../secrets/keys.nix) host;

  titosy = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINfA9T74URZ3QKWGC1guq6+WJmhCqRh0LXQ1HeFJ6O4f dev.titosy@gmail.com"
  ];

  keys = host ++ titosy;
in {
  "music.age".publicKeys = keys;
}
