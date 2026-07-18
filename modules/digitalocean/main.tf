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
    base_domain                     = var.base_domain
    acme_email                      = var.acme_email
    repo_url                        = var.cloud_apps_repo_url
    repo_ref                        = var.cloud_apps_repo_ref
    install_path                    = var.cloud_apps_install_path
    traefik_log_level               = var.traefik_log_level
    traefik_access_log              = var.traefik_access_log ? "true" : "false"
    traefik_dashboard_user          = var.traefik_dashboard_user
    traefik_dashboard_password_hash = var.traefik_dashboard_password_hash
    freecad_user                    = var.freecad_user
    freecad_password_hash           = var.freecad_password_hash
  })
}
