variable "app_name" {
  type = string
  description = "The App name to add across all resources"
  default = "hello-world"
}

variable "region" {
  type = string
  description = "The AWS region to deploy all resources to"
  default = "us-east-1"
}

variable "release_version" {
  type = string
  description = "The Docker Image version to be used in the ECS task definition"
  default = ""
}

