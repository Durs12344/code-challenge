output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.default : s.cidr_block]
}

output "web_endpoint" {
  value = "http://${aws_lb.hello_world_app_lb.dns_name}"
  description = "Hello World app web server loadbalancer endpoint"
}

output "ecr_repo_url" {
  value = aws_ecr_repository.hello_world_repo.repository_url
  description = "ECR url to push docker images"
}
