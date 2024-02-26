data "cloudflare_accounts" "retpolanne" {
  name = "retpolanne"
}

data "cloudflare_zone" "retpolannedotcom" {
  account_id = data.cloudflare_accounts.retpolanne.id
  zone_id = var.zone_id
}
