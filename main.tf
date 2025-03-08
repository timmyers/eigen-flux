terraform {
  cloud {
    organization = "eigen" # Replace with your actual organization name

    workspaces {
      name = "eigen-flux"
    }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create a new Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "primary" {
  name    = var.cluster_name
  region  = var.region
  version = var.kubernetes_version

  node_pool {
    name       = "${var.cluster_name}-worker-pool"
    size       = var.node_size
    node_count = var.node_count
  }
}
