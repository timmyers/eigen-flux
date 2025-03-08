output "cluster_endpoint" {
  value     = digitalocean_kubernetes_cluster.primary.endpoint
  sensitive = true
}

output "cluster_id" {
  value = digitalocean_kubernetes_cluster.primary.id
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.primary.kube_config[0].raw_config
  sensitive = true
}

output "cluster_status" {
  value = digitalocean_kubernetes_cluster.primary.status
}