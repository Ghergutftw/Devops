terraform {
  backend "s3" {
    bucket = "terraform-krunky"
    region = "us-east-1"
    key    = "terraform.tfstate"
  }
}