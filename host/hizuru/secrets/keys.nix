# SSH keys shared by every secret on hizuru. The host key is what agenix uses
# to decrypt secrets at activation, so it must be a recipient of all of them.
# Per-user rules (users/<name>/secrets/secrets.nix) import this.
{
  host = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIxqMaM7WSU4lJcJd65TSXkcbXX1gN7Miz0H4PRZ090Q root@nixos"
  ];
}
