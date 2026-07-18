variable "cloud_provider" {
  description = "Cloud provider to deploy to. Currently supported: digitalocean."
  type        = string
  default     = "digitalocean"

  validation {
    condition     = contains(["digitalocean"], var.cloud_provider)
    error_message = "Only \"digitalocean\" is currently supported."
  }
}

variable "base_domain" {
  description = "Base domain served by Traefik (matches BASE_DOMAIN in cloud-apps .env)."
  type        = string
}

variable "acme_email" {
  description = "Email for Let's Encrypt ACME registration."
  type        = string
}

variable "cloud_apps_repo_url" {
  description = "Git URL of the cloud-apps compose stack to deploy on the host."
  type        = string
  default     = "https://github.com/nickhedberg/cloud-apps.git"
}

variable "cloud_apps_repo_ref" {
  description = "Branch / tag / SHA of cloud_apps_repo_url to deploy."
  type        = string
  default     = "main"
}

variable "traefik_dashboard_user" {
  type    = string
  default = "admin"
}

variable "traefik_dashboard_password_hash" {
  description = "htpasswd-generated, $-doubled hash. See README."
  type        = string
  sensitive   = true
}

variable "freecad_user" {
  type    = string
  default = "admin"
}

variable "freecad_password_hash" {
  description = "htpasswd-generated, $-doubled hash. See README."
  type        = string
  sensitive   = true
}

variable "traefik_log_level" {
  type    = string
  default = "INFO"
}

variable "traefik_access_log" {
  type    = bool
  default = true
}
