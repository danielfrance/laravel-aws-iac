terraform {
  backend "s3" {
    bucket = "<your-bucket-name>" # you can't use variables here, so you need to hardcode the bucket name
    key    = "<your-key-name>"    # . e.g. dev/terraform.tfstate
    region = "<your-region>"      # e.g. us-east-1
  }
}
