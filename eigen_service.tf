# # Resources for deploying eigen-service via ArgoCD

# # Create namespace for the application
# resource "kubernetes_namespace" "eigen_service" {
#   metadata {
#     name = "eigen-service"
#   }

#   depends_on = [digitalocean_kubernetes_cluster.primary]
# }

# resource "kubernetes_manifest" "eigen_service_app" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "Application"
#     metadata = {
#       name      = "eigen-service"
#       namespace = "argocd"
#     }
#     spec = {
#       project = "default"
#       source = {
#         repoURL        = "https://github.com/timmyers/eigen-flux"
#         targetRevision = "HEAD"
#         path           = "manifests/eigen-service"
#       }
#       destination = {
#         server    = "https://kubernetes.default.svc"
#         namespace = kubernetes_namespace.eigen_service.metadata[0].name
#       }
#       syncPolicy = {
#         automated = {
#           prune      = true
#           selfHeal   = true
#           allowEmpty = false
#         }
#         syncOptions = [
#           "CreateNamespace=true"
#         ]
#       }
#     }
#   }

#   depends_on = [
#     helm_release.argocd
#   ]
# }

# # Create Certificate for the Service
# resource "kubernetes_manifest" "eigen_service_certificate" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "eigen-service-cert"
#       namespace = kubernetes_namespace.eigen_service.metadata[0].name
#     }
#     spec = {
#       secretName = "eigen-service-tls"
#       issuerRef = {
#         name  = "letsencrypt-prod"
#         kind  = "ClusterIssuer"
#       }
#       dnsNames = [
#         "eigen.tmye.me"
#       ]
#     }
#   }

#   depends_on = [
#     kubernetes_namespace.eigen_service,
#     kubernetes_manifest.cluster_issuer
#   ]
# }

# # Create DNS record for the service
# resource "cloudflare_record" "eigen_service" {
#   zone_id = var.cloudflare_zone_id
#   name    = "eigen.tmye.me"
#   content = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
#   type    = "A"
#   ttl     = 3600
#   proxied = false

#   depends_on = [data.kubernetes_service.nginx_ingress]
# }