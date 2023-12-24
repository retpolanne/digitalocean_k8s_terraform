provider "cloudflare" {}

provider "digitalocean" {
  token = var.digitalocean_token
  spaces_access_id  = var.digitalocean_access_id
  spaces_secret_key = var.digitalocean_secret_key
}
