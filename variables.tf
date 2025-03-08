variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "sfo2"
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster"
  type        = string
  default     = "eigen-k8s"
}

variable "kubernetes_version" {
  description = "The version of Kubernetes to use"
  type        = string
  default     = "1.32.2-do.0"
}

variable "node_size" {
  description = "The size of the worker nodes"
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "node_count" {
  description = "The number of worker nodes in the cluster"
  type        = number
  default     = 1
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the tmye.me domain"
  type        = string
  sensitive   = true
}

variable "letsencrypt_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
  default     = ""  # You'll want to set this in your terraform.tfvars
}
