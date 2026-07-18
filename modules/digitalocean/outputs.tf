output "server_ipv4" {
  description = "Public IPv4 of the deployed droplet."
  value       = digitalocean_droplet.this.ipv4_address
}

output "server_ipv6" {
  description = "Public IPv6 of the deployed droplet (if enabled)."
  value       = digitalocean_droplet.this.ipv6_address
}

output "server_hostname" {
  value = digitalocean_droplet.this.name
}

output "dns_records" {
  description = "DNS records created by this module."
  value = {
    wildcard = digitalocean_record.wildcard.fqdn
    apex     = digitalocean_record.apex.fqdn
  }
}

output "app_urls" {
  description = "Predicted app URLs based on the cloud-apps compose labels."
  value = {
    freecad           = "https://freecad.${var.base_domain}"
    traefik_dashboard = "https://traefik.${var.base_domain}"
  }
}

output "firewall_id" {
  value = digitalocean_firewall.this.id
}
