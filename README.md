# eigen-flux

This repository contains Terraform configuration for managing a Kubernetes cluster on DigitalOcean, with ArgoCD installed for GitOps deployment management.

## Features

- DigitalOcean Kubernetes cluster provisioning
- NGINX Ingress Controller installation
- ArgoCD deployment with public access
- Cloudflare DNS integration

## Prerequisites

- DigitalOcean API token
- Cloudflare API token with DNS edit permissions
- Cloudflare Zone ID for the tmye.me domain

## Getting Started

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your values:
   ```
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Initialize Terraform:
   ```
   terraform init
   ```

3. Apply the configuration:
   ```
   terraform apply
   ```

4. Access ArgoCD at `https://argo.eigen.tmye.me`

## Initial ArgoCD Access

After deployment, you can get the initial admin password using:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Default username is `admin`.
