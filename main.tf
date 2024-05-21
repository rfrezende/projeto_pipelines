provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# Create an ECS cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "fargate-cluster"
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
resource "aws_security_group" "ecs_service_sg" {
  name_prefix = "ecs-service-"
  description = "Allow HTTP traffic to ECS service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 9001
    to_port     = 9001
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

resource "aws_security_group" "ecs_service_private_sg" {
  name_prefix = "ecs-service-"
  description = "Allow HTTP traffic to ECS service"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

resource "aws_service_discovery_private_dns_namespace" "dns_namespace" {
  name        = "projeto.local"
  description = "Namespace para o projeto de orquestracao"
  vpc         = aws_vpc.main.id
}

# Create an ECS service
resource "aws_ecs_service" "fargate_service" {
  name            = "fargate-service"
  cluster         = aws_ecs_cluster.fargate_cluster.id
  task_definition = aws_ecs_task_definition.fargate_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.example.*.id
    security_groups = [aws_security_group.ecs_service_sg.id, aws_security_group.ecs_service_private_sg.id]
    assign_public_ip = true
  }

  service_connect_configuration {
    enabled = true
    namespace = aws_service_discovery_private_dns_namespace.dns_namespace.name
  }
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create subnets
resource "aws_subnet" "example" {
  count                   = 1
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
}

# Create an Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

# Create a route table for the public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

# Associate the public subnets with the route table
resource "aws_route_table_association" "example" {
  count          = 1
  subnet_id      = aws_subnet.example[count.index].id
  route_table_id = aws_route_table.public.id
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_cloudwatch_log_group" "logs_projeto" {
  name              = "logs_projeto"
  retention_in_days = 30
}