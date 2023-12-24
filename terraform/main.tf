resource "digitalocean_vpc" "k8s_nebula_vpc" {
  name   = "k8s-nebula-vpc"
  region = "nyc3"
}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name     = "k8s-cluster"
  region   = "nyc3"
  version  = "1.28.2-do.0"
  vpc_uuid = digitalocean_vpc.k8s_nebula_vpc.id

  node_pool {
    name       = "main-pool"
    size       = "s-2vcpu-4gb"
    node_count = 1
  }
}

provider "kubernetes" {
  host  = digitalocean_kubernetes_cluster.k8s.endpoint
  token = digitalocean_kubernetes_cluster.k8s.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    host  = digitalocean_kubernetes_cluster.k8s.endpoint
    token = digitalocean_kubernetes_cluster.k8s.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.k8s.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "kubernetes_namespace" "nginx-ingress" {
  metadata {
    name = "nginx-ingress"
  }
}

resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.9.0"
  namespace  = kubernetes_namespace.nginx-ingress.metadata.name
}

resource "helm_release" "superset" {
  name       = "superset"
  repository = "https://apache.github.io/superset"
  chart      = "superset"
  version    = "0.10.15"

  values = [
    "${file("files/values-superset.yaml")}"
  ]
}

resource "helm_release" "psql" {
  name       = "psql"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql"
  version    = "13.2.11"
}

data "kubernetes_resources" "psql_secret" {
  api_version    = "v1"
  kind           = "Secret"
  field_selector = "metadata.name==psql-postgresql"
}
