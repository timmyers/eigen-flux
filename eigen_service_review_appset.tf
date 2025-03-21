# // Terraform resource to deploy an ArgoCD ApplicationSet for review apps using pure HCL
# resource "kubernetes_manifest" "eigen_service_review_appset" {
#   manifest = {
#     apiVersion = "argoproj.io/v1alpha1"
#     kind       = "ApplicationSet"
#     metadata = {
#       name      = "eigen-service-review-apps"
#       namespace = "argocd"
#     }
#     spec = {
#       generators = [
#         {
#           pullRequest = {
#             github = {
#               api   = "https://api.github.com/"
#               owner = "timmyers"
#               repo  = "eigen-service"
#             }
#             filters = [
#               { condition = "open" }
#             ]
#           }
#         }
#       ]
#       template = {
#         metadata = {
#           name = "eigen-service-{{branch}}"
#         }
#         spec = {
#           project = "default"
#           source = {
#             repoURL        = "https://github.com/timmyers/eigen-flux"
#             targetRevision = "HEAD"
#             path           = "manifests/eigen-service-review"
#             kustomize = {
#                 images = [
#                     "ghcr.io/timmyers/eigen-service=ghcr.io/timmyers/eigen-service:review-{{branch}}-{{head_sha}}"
#                 ]
#                 patches = [
#                     {
#                         target = {
#                             kind = "Ingress"
#                             name = "eigen-service-review"
#                         }
#                         patch = <<EOF
# - op: replace
#   path: /spec/rules/0/host
#   value: "{{branch}}.eigen-review.tmye.me"
# - op: replace
#   path: /spec/tls/0/hosts/0
#   value: "{{branch}}.eigen-review.tmye.me"
# - op: replace
#   path: /metadata/name
#   value: "eigen-service-review-{{branch}}"
# - op: replace
#   path: /spec/rules/0/http/paths/0/backend/service/name
#   value: "eigen-service-review-{{branch}}"
# EOF
#                     },
#                     {
#                         target = {
#                             kind = "Deployment"
#                             name = "eigen-service-review"
#                         }
#                         patch = <<EOF
# - op: replace
#   path: /metadata/name
#   value: "eigen-service-review-{{branch}}"
# - op: replace
#   path: /spec/selector/matchLabels/app
#   value: "eigen-service-review-{{branch}}"
# - op: replace
#   path: /spec/template/metadata/labels/app
#   value: "eigen-service-review-{{branch}}"
# EOF
#                     },
#                     {
#                         target = {
#                             kind = "Service"
#                             name = "eigen-service-review"
#                         }
#                         patch = <<EOF
# - op: replace
#   path: /metadata/name
#   value: "eigen-service-review-{{branch}}"
# - op: replace
#   path: /spec/selector/app
#   value: "eigen-service-review-{{branch}}"
# EOF
#                     }
#                 ]
#             }
#           }
#           destination = {
#             server    = "https://kubernetes.default.svc"
#             namespace = kubernetes_namespace.eigen_service.metadata[0].name
#           }
#           syncPolicy = {
#             automated = {
#               prune    = true
#               selfHeal = false
#             }
#             syncOptions = ["CreateNamespace=true"]
#           }
#         }
#       }
#     }
#   }
#   depends_on = [helm_release.argocd]
# }

# // Create Certificate for the Service
# resource "kubernetes_manifest" "eigen_service_review_certificate" {
#   manifest = {
#     apiVersion = "cert-manager.io/v1"
#     kind       = "Certificate"
#     metadata = {
#       name      = "eigen-service-review-cert"
#       namespace = kubernetes_namespace.eigen_service.metadata[0].name
#     }
#     spec = {
#       secretName = "eigen-service-review-tls"
#       issuerRef = {
#         name  = "letsencrypt-prod"
#         kind  = "ClusterIssuer"
#       }
#       dnsNames = [
#         "*.eigen-review.tmye.me"
#       ]
#     }
#   }

#   depends_on = [
#     kubernetes_namespace.eigen_service,
#     kubernetes_manifest.cluster_issuer
#   ]
# }

# // Create DNS record for the service
# resource "cloudflare_record" "eigen_service_review" {
#   zone_id = var.cloudflare_zone_id
#   name    = "*.eigen-review.tmye.me"
#   content = data.kubernetes_service.nginx_ingress.status[0].load_balancer[0].ingress[0].ip
#   type    = "A"
#   ttl     = 3600
#   proxied = false

#   depends_on = [data.kubernetes_service.nginx_ingress]
# }