resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "ecs-relatorio-fraude"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      "name" : "rabbitmq-service",
      "image" : "rabbitmq:3-management",
      "portMappings" : [
        {
          "name" : "rabbitmq-service",
          "containerPort" : 15672,
          "hostPort" : 15672,
          "protocol" : "tcp"
        }
      ],
      "essential" : false,
      "environment" : [
        {
          "name" : "RABBITMQ_DEFAULT_USER",
          "value" : "${var.usuario}"
        },
        {
          "name" : "RABBITMQ_DEFAULT_PASS",
          "value" : "${var.senha}"
        },
        {
          "name" : "RABBITMQ_DEFAULT_VHOST",
          "value" : "projeto"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${aws_cloudwatch_log_group.logs_projeto.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    },
    {
      "name" : "redis-service",
      "image" : "redis/redis-stack",
      "portMappings" : [
        {
          "name" : "redis-service",
          "containerPort" : 6379,
          "hostPort" : 6379,
          "protocol" : "tcp"
        }
      ],
      "essential" : false,
      "environment" : [
        {
          "name" : "REDIS_ARGS",
          "value" : "--save 60 1000 --appendonly yes"
        },
        {
          "name" : "REDISTIMESERIES_ARGS",
          "value" : "RETENTION_POLICY=20"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${aws_cloudwatch_log_group.logs_projeto.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    },
    {
      "name" : "minio-service",
      "image" : "minio/minio",
      "portMappings" : [
        {
          "name" : "minio-service",
          "containerPort" : 9000,
          "hostPort" : 9000,
          "protocol" : "tcp"
        },
        {
          "name" : "minio-console",
          "containerPort" : 9001,
          "hostPort" : 9001,
          "protocol" : "tcp"
        }
      ],
      "command": ["server", "/data --console-address ':9001'"]
      "essential" : false,
      "environment" : [
        {
          "name" : "MINIO_ROOT_USER",
          "value" : "${var.usuario}"
        },
        {
          "name" : "MINIO_ROOT_PASSWORD",
          "value" : "${var.senha}"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${aws_cloudwatch_log_group.logs_projeto.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    },
    {
      "name" : "preparar-ambiente",
      "image" : "rfrezende/app-projeto-ada:preparar-ambiente",
      "essential" : true,
      "environment" : [
        {
          "name" : "USUARIO_PADRAO",
          "value" : "${var.usuario}"
        },
        {
          "name" : "SENHA_PADRAO",
          "value" : "${var.senha}"
        },
        {
          "name" : "PYTHONUNBUFFERED",
          "value" : "1"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${aws_cloudwatch_log_group.logs_projeto.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    },
    {
      "name" : "producer",
      "image" : "rfrezende/app-projeto-ada:producer",
      "essential" : true,
      "environment" : [
        {
          "name" : "USUARIO_PADRAO",
          "value" : "${var.usuario}"
        },
        {
          "name" : "SENHA_PADRAO",
          "value" : "${var.senha}"
        },
        {
          "name" : "PYTHONUNBUFFERED",
          "value" : "1"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${aws_cloudwatch_log_group.logs_projeto.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    },
    {
      "name" : "consumer",
      "image" : "rfrezende/app-projeto-ada:consumer",
      "essential" : true,
      "environment" : [
        {
          "name" : "USUARIO_PADRAO",
          "value" : "${var.usuario}"
        },
        {
          "name" : "SENHA_PADRAO",
          "value" : "${var.senha}"
        },
        {
          "name" : "PYTHONUNBUFFERED",
          "value" : "1"
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-create-group" : "true",
          "awslogs-group" : "${aws_cloudwatch_log_group.logs_projeto.name}",
          "awslogs-region" : "${var.region}",
          "awslogs-stream-prefix" : "ecs"
        }
      }
    }
  ])
}
