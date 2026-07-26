data "digitalocean_ssh_key" "selected" {
  for_each = toset(var.ssh_key_names)
  name     = each.value
}

data "digitalocean_domain" "this" {
  name = var.dns_domain
}

resource "digitalocean_droplet" "this" {
  name      = var.droplet_name
  region    = var.region
  size      = var.droplet_size
  image     = var.droplet_image
  ipv6      = var.enable_ipv6
  ssh_keys  = [for k in data.digitalocean_ssh_key.selected : k.id]
  tags      = ["cloud-apps", "managed-by:terraform"]
  user_data = local.user_data
}

resource "digitalocean_firewall" "this" {
  name        = "${var.droplet_name}-firewall"
  droplet_ids = [digitalocean_droplet.this.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = var.firewall_allowed_ssh_source_ranges
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_record" "wildcard" {
  domain = data.digitalocean_domain.this.name
  type   = "A"
  name   = "*"
  value  = digitalocean_droplet.this.ipv4_address
  ttl    = 300
}

resource "digitalocean_record" "apex" {
  domain = data.digitalocean_domain.this.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.this.ipv4_address
  ttl    = 300
}

locals {
  user_data = templatefile("${path.module}/cloud-init.yaml.tpl", {
    repo_url         = var.cloud_apps_repo_url
    repo_ref         = var.cloud_apps_repo_ref
    install_path     = var.cloud_apps_install_path
    env_file_content = var.env_file_content
  })
}
