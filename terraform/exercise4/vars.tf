variable "region" {
  default = "us-east-1"
}

variable "webuser" {
  default = "ubuntu"
}

variable "zone" {
  default = "us-east-1a"
}

variable "amis" {
  type = map(any)
  default = {
    "us-east-1" = "ami-020cba7c55df1f615" # Example AMI ID for Ubuntu 22.04 in us-east-1
  }
}