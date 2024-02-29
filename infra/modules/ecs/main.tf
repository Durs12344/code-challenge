resource "aws_iam_role" "ecs_task_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role_policy.json
  name = "ecs_task_execution_role"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  policy_arn = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn
  role = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_ecr_repository" "hello_world_repo" {
  name                 = "${var.app_name}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_security_group" "allow_http_lb_ingress_sg" {
  name        = "allow_http_lb_ingress_sg"
  description = "Security Group to allow tcp inbound traffic on port 80"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "HTTP from internet"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_lb_ingress_sg"
  }
}

resource "aws_security_group_rule" "allow_all_lb_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.allow_http_lb_ingress_sg.id
  source_security_group_id = aws_security_group.ecs_container_sg.id
}

resource "aws_security_group" "ecs_container_sg" {
  name        = "ecs-container-sg"
  description = "Allow http inbound traffic from ALB security group"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "tcp"
    security_groups = [aws_security_group.allow_http_lb_ingress_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-container-sg"
  }
}

resource "aws_lb" "hello_world_app_lb" {
  name                       = "hello-world-app-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.allow_http_lb_ingress_sg.id]
  subnets                    = toset(data.aws_subnets.default.ids)
  enable_deletion_protection = false
}

resource "aws_lb_listener" "hello_world_app_lb_listener" {
  load_balancer_arn = aws_lb.hello_world_app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hello_world_app_lb_tg.arn
  }
}

resource "aws_lb_target_group" "hello_world_app_lb_tg" {
  name        = "hello-world-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_ecs_cluster" "cluster" {
  name = "cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "hello_world_app_td" {
  count = var.release_version != "" ? 1 : 0
  family = "hello-world-app"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "hello-world"
      image     = "${aws_ecr_repository.hello_world_repo.repository_url}:${var.release_version}"
      essential = true

      portMappings = [
        {
          containerPort = 3000
        }
      ]
    }
  ])

  requires_compatibilities = [
    "FARGATE"
  ]

  network_mode = "awsvpc"
  cpu          = "256"
  memory       = "512"
}

resource "aws_ecs_service" "hello_world_app_ecs_service" {
  count = var.release_version != "" ? 1 : 0
  name            = "${var.app_name}-ecs-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.hello_world_app_td[0].arn
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.hello_world_app_lb_tg.arn
    container_name   = jsondecode(aws_ecs_task_definition.hello_world_app_td[0].container_definitions)[0].name
    container_port   = 3000
  }

  network_configuration {
    subnets          = toset(data.aws_subnets.default.ids)
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_container_sg.id]
  }
}
