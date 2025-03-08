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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host                   = digitalocean_kubernetes_cluster.primary.endpoint
  token                  = digitalocean_kubernetes_cluster.primary.kube_config[0].token
  cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host                   = digitalocean_kubernetes_cluster.primary.endpoint
    token                  = digitalocean_kubernetes_cluster.primary.kube_config[0].token
    cluster_ca_certificate = base64decode(digitalocean_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
  }
}

# Configure the Cloudflare Provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token
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

# Install nginx-ingress controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }

  depends_on = [digitalocean_kubernetes_cluster.primary]
}

# Install cert-manager for SSL certificates
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  version    = "v1.13.1"

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [digitalocean_kubernetes_cluster.primary]
}

# Create a ClusterIssuer for Let's Encrypt
resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}

# Install ArgoCD
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true

  values = [
    <<-EOT
    server:
      ingress:
        enabled: true
        ingressClassName: nginx
        hosts:
          - argo.eigen.tmye.me
        annotations:
          kubernetes.io/ingress.class: nginx
          cert-manager.io/cluster-issuer: "letsencrypt-prod"
          nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
          nginx.ingress.kubernetes.io/ssl-passthrough: "false" # Changed from true to false to allow cert-manager to handle SSL
          nginx.ingress.kubernetes.io/backend-protocol: "HTTP" # Changed from HTTPS to HTTP
        tls:
          - secretName: argocd-server-tls
            hosts:
              - argo.eigen.tmye.me
      extraArgs:
        - --insecure
    EOT
  ]

  depends_on = [helm_release.nginx_ingress, helm_release.cert_manager]
}

# Get load balancer IP for the ingress controller
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "ingress-nginx"
  }

  depends_on = [helm_release.nginx_ingress]
}

# Create DNS record for ArgoCD
resource "cloudflare_record" "argocd" {
  zone_id = var.cloudflare_zone_id
  name    = "argo.eigen.tmye.me"
  content = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
  type    = "A"
  ttl     = 3600
  proxied = false

  depends_on = [data.kubernetes_service.nginx_ingress]
}
