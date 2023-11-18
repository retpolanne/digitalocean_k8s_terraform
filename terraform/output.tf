output "doctl_cmdline" {
  value = "doctl kubernetes cluster kubeconfig save ${digitalocean_kubernetes_cluster.k8s.id}"
}

output "postgres_password" {
  value = base64decode(data.kubernetes_resources.psql_secret.objects[0].data.postgres-password)
}
