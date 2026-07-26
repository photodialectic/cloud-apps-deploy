locals {
  # Read the .env verbatim so terraform never has to know about individual
  # app secrets; edit them in cloud-apps with `./cloud-apps config edit`.
  env_file_content = file(var.env_file)
  base_domain      = regex("(?m)^(?:export\\s+)?BASE_DOMAIN\\s*=\\s*(.*)$", local.env_file_content)[0]
}

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

  base_domain         = local.base_domain
  env_file_content    = local.env_file_content
  cloud_apps_repo_url = var.cloud_apps_repo_url
  cloud_apps_repo_ref = var.cloud_apps_repo_ref
}

locals {
  provider_outputs = var.cloud_provider == "digitalocean" ? {
    server_ipv4     = module.digitalocean[0].server_ipv4
    server_ipv6     = module.digitalocean[0].server_ipv6
    server_hostname = module.digitalocean[0].server_hostname
    dns_records     = module.digitalocean[0].dns_records
    base_domain     = module.digitalocean[0].base_domain
    } : {
    server_ipv4     = null
    server_ipv6     = null
    server_hostname = null
    dns_records     = null
    base_domain     = null
  }
}
