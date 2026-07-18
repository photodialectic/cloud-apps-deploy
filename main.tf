module "digitalocean" {
  count  = var.cloud_provider == "digitalocean" ? 1 : 0
  source = "./modules/digitalocean"

  region                             = var.do_region
  droplet_size                       = var.do_droplet_size
  droplet_image                      = var.do_droplet_image
  droplet_name                       = var.do_droplet_name
  ssh_key_names                      = var.do_ssh_key_names
  enable_ipv6                        = var.do_enable_ipv6
  dns_domain                         = var.do_dns_domain
  firewall_allowed_ssh_source_ranges = var.do_firewall_ssh_source_ranges

  base_domain         = var.base_domain
  acme_email          = var.acme_email
  cloud_apps_repo_url = var.cloud_apps_repo_url
  cloud_apps_repo_ref = var.cloud_apps_repo_ref

  traefik_log_level               = var.traefik_log_level
  traefik_access_log              = var.traefik_access_log
  traefik_dashboard_user          = var.traefik_dashboard_user
  traefik_dashboard_password_hash = var.traefik_dashboard_password_hash
  freecad_user                    = var.freecad_user
  freecad_password_hash           = var.freecad_password_hash
}

locals {
  provider_outputs = var.cloud_provider == "digitalocean" ? {
    server_ipv4     = module.digitalocean[0].server_ipv4
    server_ipv6     = module.digitalocean[0].server_ipv6
    server_hostname = module.digitalocean[0].server_hostname
    dns_records     = module.digitalocean[0].dns_records
    app_urls        = module.digitalocean[0].app_urls
    } : {
    server_ipv4     = null
    server_ipv6     = null
    server_hostname = null
    dns_records     = null
    app_urls        = null
  }
}
