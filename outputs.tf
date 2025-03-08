output "droplet_ip" {
  value       = digitalocean_droplet.web.ipv4_address
  description = "The public IP address of the web server"
}

output "droplet_id" {
  value       = digitalocean_droplet.web.id
  description = "The ID of the droplet"
}

output "droplet_urn" {
  value       = digitalocean_droplet.web.urn
  description = "The uniform resource name of the droplet"
}