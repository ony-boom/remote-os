# Credentials come from CNTB_OAUTH2_CLIENT_ID, CNTB_OAUTH2_CLIENT_SECRET,
# CNTB_OAUTH2_USER and CNTB_OAUTH2_PASS.
terraform {
  required_providers {
    contabo = {
      source  = "contabo/contabo"
      version = "~> 0.1.44"
    }
  }
}

# name = { product_id = "...", region = "EU" }
# Removing an entry cancels that VPS.
variable "hosts" {
  type = map(object({
    product_id = string
    region     = optional(string, "EU")
    period     = optional(number, 1)
  }))
  default = {}
}

resource "contabo_secret" "ssh" {
  name  = "remote-os"
  type  = "ssh"
  value = trimspace(file("${path.module}/ssh.pub"))
}

resource "contabo_instance" "host" {
  for_each     = var.hosts
  display_name = each.key
  product_id   = each.value.product_id
  region       = each.value.region
  period       = each.value.period
  default_user = "root"
  ssh_keys     = [tonumber(contabo_secret.ssh.id)]
}

# Runs once per instance; later changes go through colmena.
module "install" {
  source      = "github.com/nix-community/nixos-anywhere//terraform/install?ref=1.13.0"
  for_each    = contabo_instance.host
  target_host = each.value.ip_config[0].v4[0].ip
  instance_id = each.value.id
  flake       = "${abspath("${path.module}/..")}#generic"
}

output "ips" {
  value = { for name, host in contabo_instance.host : name => host.ip_config[0].v4[0].ip }
}
