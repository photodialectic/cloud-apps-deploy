variable "cloud_provider" {
  description = "Cloud provider to deploy to. Currently supported: digitalocean."
  type        = string
  default     = "digitalocean"

  validation {
    condition     = contains(["digitalocean"], var.cloud_provider)
    error_message = "Only \"digitalocean\" is currently supported."
  }
}

variable "env_file" {
  description = <<-EOT
    Path to a cloud-apps .env file (see cloud-apps/.env.example). Its contents
    are copied verbatim to the droplet as /opt/cloud-apps/.env, so all app
    config (BASE_DOMAIN, ACME_EMAIL, TRAEFIK_*, CLOUD_APP_*) is managed there
    with `./cloud-apps config edit`/`config set`, not here.
  EOT
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

