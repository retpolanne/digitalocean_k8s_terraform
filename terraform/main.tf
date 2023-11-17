resource "digitalocean_vpc" "k8s_nebula_vpc" {
  name   = "k8s-nebula-vpc"
  region = "nyc3"
}

data "cloudinit_config" "nebula_cloudinit" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "nebula_config_lighthouse.yaml"
    content_type = "jinja2"

    content = file("${path.module}/nebula_config_lighthouse.yaml")
  }

  part {
    filename     = "cloud-init.yaml"
    content_type = "text/cloud-config"

    content = file("${path.module}/cloud-init.yaml")
  }
}

resource "digitalocean_droplet" "nebula" {
  name      = "nebula"
  size      = "s-1vcpu-1gb"
  image     = "debian-12-x64"
  region    = "nyc3"
  vpc_uuid  = digitalocean_vpc.k8s_nebula_vpc.id
  user_data = data.cloudinit_config.nebula_cloudinit.rendered
}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name     = "k8s-cluster"
  region   = "nyc3"
  version  = "1.28.2-do.0"
  vpc_uuid = digitalocean_vpc.k8s_nebula_vpc.id

  node_pool {
    name       = "main-pool"
    size       = "s-2vcpu-2gb"
    node_count = 1
  }
}
