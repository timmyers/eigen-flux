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
