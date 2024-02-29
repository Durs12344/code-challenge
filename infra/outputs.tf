output "ecr_repo_url" {
  value = module.ecs.ecr_repo_url
  description = "ECR url to push docker images"
}

output "subnet_cidr_blocks" {
  value = module.ecs.subnet_cidr_blocks
}

output "vpc_id" {
  value = module.ecs.vpc_id
}

output "web_endpoint" {
  value = module.ecs.web_endpoint
  description = "Hello World app web server loadbalancer endpoint"
}
