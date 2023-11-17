terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://nyc3.digitaloceanspaces.com"
    }
    bucket = "terraform-state-backend-bucket"
    region = "us-west-1"
    key = "terraform.tfstate"
    skip_credentials_validation = true
    skip_metadata_api_check = true
    skip_requesting_account_id = true
    skip_s3_checksum = true
  }
}
