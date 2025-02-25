terraform {
  backend "s3" {
    bucket = var.tfstate_bucket
    key    = "${var.environment}/terraform.tfstate"
    region = "us-east-1"
  }
}
