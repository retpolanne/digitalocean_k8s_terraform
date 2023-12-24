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

resource "digitalocean_ssh_key" "mba" {
  name       = "Macbook Air"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFvxXEF5EX02z8V/hHD8vvDBL7fQHxsAhgTs33tBf/zw"
}

resource "digitalocean_droplet" "openvpn" {
  image     = "openvpn-18-04"
  name      = "openvpn"
  region    = "nyc3"
  size      = "s-1vcpu-1gb"
  ssh_keys  = [digitalocean_ssh_key.mba.fingerprint]
}

data "cloudflare_accounts" "retpolanne" {
  name = "retpolanne"
}

data "cloudflare_zone" "retpolannedotcom" {
  account_id = data.cloudflare_accounts.retpolanne.id
  zone_id = var.zone_id
}

resource "cloudflare_record" "openvpn" {
  zone_id = data.cloudflare_zone.retpolannedotcom.id
  name    = "openvpn"
  value   = digitalocean_droplet.openvpn.ipv4_address
  type    = "A"
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
  namespace  = "nginx-ingress"

  set {
    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-enable-proxy-protocol"
    value = "true"
  }

  set {
    name = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name = "controller.config.use-proxy-protocol"
    value = "true"
  }

  set {
    name = "controller.config.use-forward-headers"
    value = "true"
  }
}

data "kubernetes_service" "nginx-ingress-svc" {
  metadata {
    name = "nginx-ingress-ingress-nginx-controller"
    namespace = "nginx-ingress"
  }
}

resource "cloudflare_record" "nginx" {
  zone_id = data.cloudflare_zone.retpolannedotcom.id
  name    = "nginx"
  value   = data.kubernetes_service.nginx-ingress-svc.status.0.load_balancer.0.ingress.0.ip
  type    = "A"
}

resource "cloudflare_record" "superset" {
  zone_id = data.cloudflare_zone.retpolannedotcom.id
  name    = "superset"
  value   = data.kubernetes_service.nginx-ingress-svc.status.0.load_balancer.0.ingress.0.ip
  type    = "A"
}

resource "helm_release" "superset" {
  name       = "superset"
  repository = "https://apache.github.io/superset"
  chart      = "superset"
  version    = "0.10.15"

  set {
    name = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/whitelist-source-range"
    value = digitalocean_droplet.openvpn.ipv4_address_private
  }

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

