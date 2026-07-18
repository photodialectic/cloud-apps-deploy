output "cloud_provider" {
  value = var.cloud_provider
}

output "server_ipv4" {
  value = local.provider_outputs.server_ipv4
}

output "server_ipv6" {
  value = local.provider_outputs.server_ipv6
}

output "server_hostname" {
  value = local.provider_outputs.server_hostname
}

output "dns_records" {
  value = local.provider_outputs.dns_records
}

output "app_urls" {
  value = local.provider_outputs.app_urls
}
