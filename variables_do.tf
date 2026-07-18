# DigitalOcean-specific knobs. Ignored when cloud_provider != "digitalocean".
variable "do_region" {
  type    = string
  default = "nyc3"
}

variable "do_droplet_size" {
  type    = string
  default = "s-2vcpu-4gb"
}

variable "do_droplet_image" {
  type    = string
  default = "docker-20-04"
}

variable "do_droplet_name" {
  type    = string
  default = "cloud-apps"
}

variable "do_ssh_key_names" {
  description = "Names of SSH keys already uploaded to your DigitalOcean account."
  type        = list(string)
  default     = []
}

variable "do_dns_domain" {
  description = "Domain name managed by DigitalOcean DNS. Must already exist in your DO account (import or create it separately)."
  type        = string
}

variable "do_firewall_ssh_source_ranges" {
  description = "CIDRs allowed to reach SSH. Default: anywhere. Restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "do_enable_ipv6" {
  type    = bool
  default = true
}
