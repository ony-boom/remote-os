# agenix rules for ony's secrets. Run `agenix -e <file>.age` from this folder.
let
  inherit (import ../../../secrets/keys.nix) host;

  ony = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHv9QaJuLjfAa2M6VFvfPOq8jAwfbI7JZmf8zpmFAob ony@hizuru"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki"
  ];

  keys = host ++ ony;
in {
  "copyparty.age".publicKeys = keys;
  "umami.age".publicKeys = keys;
  "webhooks.age".publicKeys = keys;
  "navidrome.age".publicKeys = keys;
  "couchdb.age".publicKeys = keys;
}
