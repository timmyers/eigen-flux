// Terraform resource to deploy an ArgoCD ApplicationSet for review apps
// This ApplicationSet automatically creates an ArgoCD Application for every open pull request
// in the designated GitHub repository. Each review app deploys the eigen-service using the branch
// of the PR. For review apps, the destination namespace is set to "eigen-service-{{branch}}" and it is expected
// that the manifests in the branch override the ingress host to use "{{branch}}.eigen-review.tmye.me".

resource "kubernetes_manifest" "eigen_service_review_appset" {
  manifest = yamldecode(<<EOF
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: eigen-service-review-apps
  namespace: argocd
spec:
  generators:
    - pullRequest:
        # Generator configuration for GitHub Pull Requests
        # Ensure you have a Kubernetes secret (e.g. 'github-api') with your GitHub API token
        # apiTokenRef:
        #   name: github-api
        #   key: token
        owner: timmyers
        repo: eigen-service
        # Uncomment below to filter only open PRs if needed
        filters:
          - condition: "open"
  template:
    metadata:
      name: eigen-service-{{branch}}
    spec:
      project: default
      source:
        repoURL: "https://github.com/timmyers/eigen-flux"
        targetRevision: "HEAD"
        path: "manifests/eigen-service"
        plugin:
          name: kustomize
          parameters:
            - name: images
              value: ghcr.io/timmyers/eigen-service:review-{{branch}}
      destination:
        server: "https://kubernetes.default.svc"
        namespace: eigen-service-{{branch}}
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF
  )
  depends_on = [helm_release.argocd]
}
