# ================================================
# ECS Module — Fargate + EC2 Side-by-Side
# Author: Ahmad Khorsandi Pour
# ================================================
# This module manages two ECS launch types running
# in the same production cluster simultaneously:
#
# ECS Fargate → Next.js frontend + React admin
#   · Serverless containers — no instance management
#   · Scales per-task — cost efficient for variable load
#   · Used when instance-level control is not needed
#
# ECS EC2 → Laravel backend
#   · Instance-level control for tuning PHP-FPM workers
#   · Predictable performance during festival peak load
#   · Used when Fargate resource limits are a constraint
#
# Both types share the same cluster, ALB, and
# ECR registry — only the launch type differs.
# ================================================

# ================================================
# VARIABLES
# ================================================

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "cluster_arn" {
  description = "ECS cluster ARN"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "alb_target_group_backend_arn" {
  description = "ALB target group ARN for Laravel backend"
  type        = string
}

variable "alb_target_group_frontend_arn" {
  description = "ALB target group ARN for Next.js frontend"
  type        = string
}

variable "ecr_backend_image" {
  description = "ECR image URI for Laravel backend"
  type        = string
}

variable "ecr_frontend_image" {
  description = "ECR image URI for Next.js frontend"
  type        = string
}

variable "backend_cpu" {
  type    = number
  default = 1024
}

variable "backend_memory" {
  type    = number
  default = 2048
}

variable "frontend_cpu" {
  type    = number
  default = 512
}

variable "frontend_memory" {
  type    = number
  default = 1024
}

variable "backend_desired_count" {
  type    = number
  default = 2
}

variable "frontend_desired_count" {
  type    = number
  default = 2
}

variable "aws_region" {
  type    = string
  default = "me-south-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "db_host" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type      = string
  sensitive = true
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "app_key" {
  description = "Laravel APP_KEY"
  type        = string
  sensitive   = true
}

# ================================================
# IAM — TASK EXECUTION ROLE
# ================================================

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${var.cluster_name}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Extra permissions — ECR + Secrets Manager + CloudWatch
resource "aws_iam_role_policy" "ecs_task_execution_extras" {
  name = "${var.cluster_name}-task-execution-extras"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}

# ================================================
# CLOUDWATCH LOG GROUPS
# ================================================

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.cluster_name}/laravel-backend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.cluster_name}/nextjs-frontend"
  retention_in_days = 30
}

# ================================================
# ECS EC2 — LARAVEL BACKEND
# Launch type: EC2 (instance-level control)
# Reason: PHP-FPM worker tuning + predictable 
#         performance during 30,000+ TPS peak
# ================================================

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.cluster_name}-laravel-backend"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "laravel-app"
      image     = var.ecr_backend_image
      essential = true

      portMappings = [
        {
          containerPort = 9000
          hostPort      = 9000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "APP_ENV"
          value = var.environment
        },
        {
          name  = "APP_DEBUG"
          value = "false"
        },
        {
          name  = "DB_CONNECTION"
          value = "mysql"
        },
        {
          name  = "DB_PORT"
          value = "3306"
        }
      ]

      secrets = [
        {
          name      = "APP_KEY"
          valueFrom = "arn:aws:ssm:${var.aws_region}:[ACCOUNT-REDACTED]:parameter/production/APP_KEY"
        },
        {
          name      = "DB_HOST"
          valueFrom = "arn:aws:ssm:${var.aws_region}:[ACCOUNT-REDACTED]:parameter/production/DB_HOST"
        },
        {
          name      = "DB_DATABASE"
          valueFrom = "arn:aws:ssm:${var.aws_region}:[ACCOUNT-REDACTED]:parameter/production/DB_DATABASE"
        },
        {
          name      = "DB_USERNAME"
          valueFrom = "arn:aws:ssm:${var.aws_region}:[ACCOUNT-REDACTED]:parameter/production/DB_USERNAME"
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = "arn:aws:ssm:${var.aws_region}:[ACCOUNT-REDACTED]:parameter/production/DB_PASSWORD"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "laravel"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      mountPoints  = []
      volumesFrom  = []
    }
  ])
}

resource "aws_ecs_service" "backend" {
  name            = "laravel-backend"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count

  # EC2 launch type — instance-level control
  launch_type = "EC2"

  # Rolling deployment — no downtime during deploys
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_backend_arn
    container_name   = "laravel-app"
    container_port   = 9000
  }

  lifecycle {
    ignore_changes = [
      # CI/CD manages image updates — Terraform
      # should not revert to old image on next apply
      task_definition,
      desired_count
    ]
  }
}

# ================================================
# ECS FARGATE — NEXT.JS FRONTEND
# Launch type: Fargate (serverless)
# Reason: Variable traffic — scales per-task,
#         no instance management overhead
# ================================================

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.cluster_name}-nextjs-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "nextjs-app"
      image     = var.ecr_frontend_image
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "NEXT_TELEMETRY_DISABLED"
          value = "1"
        }
      ]

      secrets = [
        {
          name      = "NEXT_PUBLIC_API_URL"
          valueFrom = "arn:aws:ssm:${var.aws_region}:[ACCOUNT-REDACTED]:parameter/production/API_URL"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "nextjs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000 || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      mountPoints = []
      volumesFrom = []
    }
  ])
}

resource "aws_ecs_service" "frontend" {
  name            = "nextjs-frontend"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count

  # Fargate launch type — serverless
  launch_type = "FARGATE"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_frontend_arn
    container_name   = "nextjs-app"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [
      task_definition,
      desired_count
    ]
  }
}

# ================================================
# AUTO SCALING — BACKEND (EC2 launch type)
# ================================================

resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 20
  min_capacity       = 2
  resource_id        = "service/${var.cluster_name}/laravel-backend"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.backend]
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "backend-cpu-scale-out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    # Scale out at 70% CPU — tested during festival load
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "backend_memory" {
  name               = "backend-memory-scale-out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 75.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ================================================
# AUTO SCALING — FRONTEND (Fargate)
# ================================================

resource "aws_appautoscaling_target" "frontend" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${var.cluster_name}/nextjs-frontend"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.frontend]
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "frontend-cpu-scale-out"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ================================================
# OUTPUTS
# ================================================

output "backend_service_name" {
  description = "ECS backend service name"
  value       = aws_ecs_service.backend.name
}

output "frontend_service_name" {
  description = "ECS frontend service name"
  value       = aws_ecs_service.frontend.name
}

output "backend_task_definition_arn" {
  description = "Latest backend task definition ARN"
  value       = aws_ecs_task_definition.backend.arn
}

output "frontend_task_definition_arn" {
  description = "Latest frontend task definition ARN"
  value       = aws_ecs_task_definition.frontend.arn
}

output "ecs_execution_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "backend_log_group" {
  description = "CloudWatch log group for Laravel backend"
  value       = aws_cloudwatch_log_group.backend.name
}

output "frontend_log_group" {
  description = "CloudWatch log group for Next.js frontend"
  value       = aws_cloudwatch_log_group.frontend.name
}
