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

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_namespace" "istio-ingress" {
  metadata {
    name = "istio-ingress"
  }
}

resource "helm_release" "istio-base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = "1.20.1"
  namespace  = "istio-system"
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = "1.20.1"
  namespace  = "istio-system"
}

resource "helm_release" "istio-ingress" {
  name       = "istio-ingress"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = "1.20.1"
  namespace  = "istio-ingress"
  depends_on = [helm_release.istiod]
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
