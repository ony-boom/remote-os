let
  hizuru = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIxqMaM7WSU4lJcJd65TSXkcbXX1gN7Miz0H4PRZ090Q root@nixos"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHHv9QaJuLjfAa2M6VFvfPOq8jAwfbI7JZmf8zpmFAob ony@hizuru"
  ];

  maki = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+IhjgxWSqhWo6ER2Gw4qyRb5JS7ioJIAKRZFJaId/y ony@maki"
  ];
in {
  "umami.age".publicKeys = hizuru ++ maki;
  "gh-hooks.age".publicKeys = hizuru ++ maki;
}
