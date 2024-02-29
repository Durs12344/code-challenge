terraform {
  backend "s3" {
    bucket = "hello-world-app-tf-state-bucket"
    key    = "infra/poc/ecs"
    region = "us-east-1"
  }
}

provider "aws" {
  region  = var.region
  profile = "default"
}

module "ecs" {
  source = "./modules/ecs"

  app_name          = var.app_name
  region            = var.region
  release_version   = var.release_version
}