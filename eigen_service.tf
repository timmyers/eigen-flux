# Resources for deploying eigen-service via ArgoCD

# Create namespace for the application
resource "kubernetes_namespace" "eigen_service" {
  metadata {
    name = "eigen-service"
  }

  depends_on = [digitalocean_kubernetes_cluster.primary]
}

# Create a Kubernetes ConfigMap with the application manifests
resource "kubernetes_config_map" "eigen_service_manifests" {
  metadata {
    name      = "eigen-service-manifests"
    namespace = kubernetes_namespace.eigen_service.metadata[0].name
  }

  data = {
    "deployment.yaml" = <<-EOT
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: eigen-service
        namespace: eigen-service
      spec:
        replicas: 1
        selector:
          matchLabels:
            app: eigen-service
        template:
          metadata:
            labels:
              app: eigen-service
          spec:
            containers:
            - name: eigen-service
              image: ghcr.io/timmyers/eigen-service:1.0.8
              ports:
              - containerPort: 3000
              resources:
                limits:
                  cpu: "500m"
                  memory: "512Mi"
                requests:
                  cpu: "100m"
                  memory: "128Mi"
    EOT
    "service.yaml" = <<-EOT
      apiVersion: v1
      kind: Service
      metadata:
        name: eigen-service
        namespace: eigen-service
      spec:
        selector:
          app: eigen-service
        ports:
        - port: 80
          targetPort: 3000
        type: ClusterIP
    EOT
    "ingress.yaml" = <<-EOT
      apiVersion: networking.k8s.io/v1
      kind: Ingress
      metadata:
        name: eigen-service-ingress
        namespace: eigen-service
        annotations:
          cert-manager.io/cluster-issuer: "letsencrypt-prod"
          nginx.ingress.kubernetes.io/ssl-redirect: "true"
      spec:
        ingressClassName: nginx
        tls:
        - hosts:
          - eigen.tmye.me
          secretName: eigen-service-tls
        rules:
        - host: eigen.tmye.me
          http:
            paths:
            - path: /
              pathType: Prefix
              backend:
                service:
                  name: eigen-service
                  port:
                    number: 80
    EOT
  }

  depends_on = [kubernetes_namespace.eigen_service]
}

# Create ArgoCD Application resource
resource "kubernetes_manifest" "eigen_service_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "eigen-service"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/ArgoProj/applicationset" # Only needed as a placeholder, we're using the inline manifests
        targetRevision = "HEAD"
        chart          = ""
        plugin = {
          name = "configmap"
          env = [
            {
              name  = "CONFIGMAP_NAME"
              value = kubernetes_config_map.eigen_service_manifests.metadata[0].name
            },
            {
              name  = "CONFIGMAP_NAMESPACE"
              value = kubernetes_namespace.eigen_service.metadata[0].name
            }
          ]
        }
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = kubernetes_namespace.eigen_service.metadata[0].name
      }
      syncPolicy = {
        automated = {
          prune       = true
          selfHeal    = true
          allowEmpty  = false
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_config_map.eigen_service_manifests
  ]
}

# Create Certificate for the Service
resource "kubernetes_manifest" "eigen_service_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "eigen-service-cert"
      namespace = kubernetes_namespace.eigen_service.metadata[0].name
    }
    spec = {
      secretName = "eigen-service-tls"
      issuerRef = {
        name  = "letsencrypt-prod"
        kind  = "ClusterIssuer"
      }
      dnsNames = [
        "eigen.tmye.me"
      ]
    }
  }

  depends_on = [
    kubernetes_namespace.eigen_service,
    kubernetes_manifest.cluster_issuer
  ]
}

# Create DNS record for the service
resource "cloudflare_record" "eigen_service" {
  zone_id = var.cloudflare_zone_id
  name    = "eigen.tmye.me"
  content = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
  type    = "A"
  ttl     = 3600
  proxied = false

  depends_on = [data.kubernetes_service.nginx_ingress]
}