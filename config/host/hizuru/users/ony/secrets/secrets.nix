# agenix rules for ony's secrets. Run `agenix -e <file>.age` from this folder.
let
  inherit (import ../../../secrets/keys.nix) host;

  ony = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHv9QaJuLjfAa2M6VFvfPOq8jAwfbI7JZmf8zpmFAob ony@hizuru"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki"
  ];

  keys = host ++ ony;
in {
  "garage.age".publicKeys = keys;
  # Raw token only (openssl rand -hex 32), NOT KEY=value: aria2 reads it via
  # LoadCredential and appends it to its own conf.
  "aria2.age".publicKeys = keys;
  "jdownloader.age".publicKeys = keys;
  "umami.age".publicKeys = keys;
  "navidrome.age".publicKeys = keys;
  "couchdb.age".publicKeys = keys;
  "invoice-ninja.age".publicKeys = keys;
  "caddy.age".publicKeys = keys;
}
