provider "aws" {
  region = var.region
}

# Create an ECS cluster
resource "aws_ecs_cluster" "relatorios_antifraudes" {
  name = "relatorio-antifraudes"
}

# Create an IAM role for ECS task execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRoleTeste"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the required policy to the IAM role
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create a security group to allow traffic
resource "aws_security_group" "sg_servicos_public" {
  name_prefix = "ecs-service-"
  description = "Allow HTTP traffic to ECS service"
  vpc_id      = aws_vpc.vpc_relatorios_fraudes.id

  ingress { # MinIO
    from_port   = 9001
    to_port     = 9001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # RabbitMQ
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # Redis
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_servicos_private" {
  name_prefix = "ecs-service-"
  description = "Allow HTTP traffic to ECS service"
  vpc_id      = aws_vpc.vpc_relatorios_fraudes.id

  ingress { # MinIO
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # RabbitMQ
    from_port   = 5672
    to_port     = 5672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # Redis
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_private_dns_namespace" "dns_namespace_relatorios_fraudes" {
  name        = "projeto.local"
  description = "Namespace para o projeto de orquestracao"
  vpc         = aws_vpc.vpc_relatorios_fraudes.id
}

# Create a VPC
resource "aws_vpc" "vpc_relatorios_fraudes" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "sn_relatorios_fraudes" {
  vpc_id                  = aws_vpc.vpc_relatorios_fraudes.id
  cidr_block              = cidrsubnet(aws_vpc.vpc_relatorios_fraudes.cidr_block, 8, 1)
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
}

# Create an Internet Gateway
resource "aws_internet_gateway" "vpc_relatorios_fraudes" {
  vpc_id = aws_vpc.vpc_relatorios_fraudes.id
}

# Create a route table for the public subnets
resource "aws_route_table" "rt_internet" {
  vpc_id = aws_vpc.vpc_relatorios_fraudes.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_relatorios_fraudes.id
  }
}

# Associate the public subnets with the route table
resource "aws_route_table_association" "rta_relatorios_fraudes" {
  count          = 1
  subnet_id      = aws_subnet.sn_relatorios_fraudes.id
  route_table_id = aws_route_table.rt_internet.id
}

resource "aws_cloudwatch_log_group" "logs_projeto" {
  name              = "logs-projeto"
  retention_in_days = 30
}

# RabbitMQ
resource "aws_ecs_service" "sv_relatorios_antifraudes" {
  name            = "sv-relatorios-antifraudes"
  cluster         = aws_ecs_cluster.relatorios_antifraudes.id
  task_definition = aws_ecs_task_definition.task_rabbitmq.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.sn_relatorios_fraudes.id]
    security_groups = [aws_security_group.sg_servicos_public.id, aws_security_group.sg_servicos_private.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dns_namespace_relatorios_fraudes.name
  }
}

# # Redis
# resource "aws_ecs_service" "sv_redis" {
#   name            = "sv-redis"
#   cluster         = aws_ecs_cluster.relatorios_antifraudes.id
#   task_definition = aws_ecs_task_definition.task_redis.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets         = [aws_subnet.sn_relatorios_fraudes.id]
#     security_groups = [aws_security_group.sg_servicos_public.id, aws_security_group.sg_servicos_private.id]
#     assign_public_ip = true
#   }

#   service_connect_configuration {
#     enabled = true
#     namespace = aws_service_discovery_private_dns_namespace.dns_namespace_relatorios_fraudes.name
#   }
# }

# # MinIO
# resource "aws_ecs_service" "sv_minio" {
#   name            = "sv-minio"
#   cluster         = aws_ecs_cluster.relatorios_antifraudes.id
#   task_definition = aws_ecs_task_definition.task_minio.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets         = [aws_subnet.sn_relatorios_fraudes.id]
#     security_groups = [aws_security_group.sg_servicos_public.id, aws_security_group.sg_servicos_private.id]
#     assign_public_ip = true
#   }

#   service_connect_configuration {
#     enabled = true
#     namespace = aws_service_discovery_private_dns_namespace.dns_namespace_relatorios_fraudes.name
#   }
# }

# # Aplicacoes
# resource "aws_ecs_service" "sv_aplicacoes" {
#   name            = "sv-aplicacoes"
#   cluster         = aws_ecs_cluster.relatorios_antifraudes.id
#   task_definition = aws_ecs_task_definition.task_aplicacoes.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"
#   depends_on = [ aws_ecs_service.sv_rabbitmq, aws_ecs_service.sv_redis, aws_ecs_service.sv_minio ]
#   network_configuration {
#     subnets         = [aws_subnet.sn_relatorios_fraudes.id]
#     security_groups = [aws_security_group.sg_servicos_public.id, aws_security_group.sg_servicos_private.id]
#     assign_public_ip = true
#   }

#   service_connect_configuration {
#     enabled = true
#     namespace = aws_service_discovery_private_dns_namespace.dns_namespace_relatorios_fraudes.name
#   }
# }
