variable "region" {
  description = "DigitalOcean region for the droplet (e.g. nyc3, sfo3, ams3)."
  type        = string
  default     = "nyc3"
}

variable "droplet_size" {
  description = "Droplet slug (e.g. s-1vcpu-2gb, s-2vcpu-4gb). FreeCAD benefits from >=2GB."
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "droplet_image" {
  description = "Droplet base image slug."
  type        = string
  default     = "docker-20-04"
}

variable "droplet_name" {
  description = "Name applied to the droplet and its hostname."
  type        = string
  default     = "cloud-apps"
}

variable "ssh_key_names" {
  description = "Names of DigitalOcean SSH keys (already uploaded to your account) to inject into the droplet."
  type        = list(string)
  default     = []
}

variable "enable_ipv6" {
  description = "Enable IPv6 on the droplet."
  type        = bool
  default     = true
}

variable "dns_domain" {
  description = "DigitalOcean-managed domain name to create records under. The domain must already be registered with DigitalOcean DNS (import or create separately)."
  type        = string
}

variable "firewall_allowed_ssh_source_ranges" {
  description = "CIDR ranges allowed to reach SSH (port 22). Defaults to anywhere; restrict in production."
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "base_domain" {
  description = "Base domain used by cloud-apps (matches BASE_DOMAIN in the compose .env). Must be the same as or a subdomain of dns_domain."
  type        = string
}

variable "cloud_apps_repo_url" {
  description = "Git repository URL for the cloud-apps docker-compose stack."
  type        = string
  default     = "https://github.com/nickhedberg/cloud-apps.git"
}

variable "cloud_apps_repo_ref" {
  description = "Branch, tag, or commit SHA to check out for cloud_apps_repo_url."
  type        = string
  default     = "main"
}

variable "cloud_apps_install_path" {
  description = "Path on the droplet where cloud-apps is cloned and run."
  type        = string
  default     = "/opt/cloud-apps"
}

variable "env_file_content" {
  description = "Raw contents of a cloud-apps .env file, written verbatim to /opt/cloud-apps/.env on the droplet."
  type        = string
  sensitive   = true
}
