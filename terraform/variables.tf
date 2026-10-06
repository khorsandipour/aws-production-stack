# ================================================
# Variables — AWS Production Stack
# Author: Ahmad Khorsandi Pour
# ================================================
# IMPORTANT: Never commit terraform.tfvars
# Use AWS Secrets Manager or environment variables
# for sensitive values in production
# ================================================

# ================================================
# GENERAL
# ================================================

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "me-south-1"
}

variable "project_name" {
  description = "Project name — used as prefix for all resources"
  type        = string
  default     = "fintech-saas"

  validation {
    condition     = length(var.project_name) <= 20
    error_message = "Project name must be 20 characters or less."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"

  validation {
    condition = contains(
      ["production", "staging", "development"],
      var.environment
    )
    error_message = "Environment must be production, staging, or development."
  }
}

# ================================================
# NETWORKING
# ================================================

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to deploy into"
  type        = list(string)
  default     = ["me-south-1a", "me-south-1b", "me-south-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = [
    "10.0.11.0/24",
    "10.0.12.0/24",
    "10.0.13.0/24"
  ]
}

# ================================================
# ECS
# ================================================

variable "backend_image" {
  description = "Docker image URI for Laravel backend (from ECR)"
  type        = string
  # Example: 123456789.dkr.ecr.me-south-1.amazonaws.com/app-backend:latest
  # Set via CI/CD pipeline — do not hardcode here
}

variable "frontend_image" {
  description = "Docker image URI for Next.js frontend (from ECR)"
  type        = string
  # Set via CI/CD pipeline — do not hardcode here
}

variable "backend_cpu" {
  description = "CPU units for Laravel backend task (1024 = 1 vCPU)"
  type        = number
  default     = 1024

  validation {
    condition = contains(
      [256, 512, 1024, 2048, 4096],
      var.backend_cpu
    )
    error_message = "CPU must be a valid Fargate CPU value."
  }
}

variable "backend_memory" {
  description = "Memory (MB) for Laravel backend task"
  type        = number
  default     = 2048
}

variable "frontend_cpu" {
  description = "CPU units for Next.js frontend task"
  type        = number
  default     = 512
}

variable "frontend_memory" {
  description = "Memory (MB) for Next.js frontend task"
  type        = number
  default     = 1024
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks"
  type        = number
  default     = 2
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks"
  type        = number
  default     = 2
}

variable "backend_max_count" {
  description = "Maximum backend tasks during auto scaling"
  type        = number
  default     = 20
}

variable "backend_min_count" {
  description = "Minimum backend tasks (never scale below this)"
  type        = number
  default     = 2
}

variable "cpu_scale_out_threshold" {
  description = "CPU % that triggers scale-out"
  type        = number
  default     = 70
}

variable "scale_out_cooldown" {
  description = "Seconds to wait before scaling out again"
  type        = number
  default     = 60
}

variable "scale_in_cooldown" {
  description = "Seconds to wait before scaling in"
  type        = number
  default     = 300
}

# ================================================
# RDS
# ================================================

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "Database name"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 16
    error_message = "Database password must be at least 16 characters."
  }
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GB"
  type        = number
  default     = 100
}

variable "db_max_allocated_storage" {
  description = "Maximum RDS storage in GB (autoscaling ceiling)"
  type        = number
  default     = 500
}

variable "db_backup_retention_days" {
  description = "Days to retain automated RDS backups"
  type        = number
  default     = 7

  validation {
    condition     = var.db_backup_retention_days >= 7
    error_message = "Backup retention must be at least 7 days for production."
  }
}

# ================================================
# WAF
# ================================================

variable "waf_rate_limit" {
  description = "Max requests per 5 minutes per IP before blocking"
  type        = number
  default     = 2000
}

variable "waf_block_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
  # Example: ["KP", "IR"] — leave empty to allow all countries
}

# ================================================
# CLOUDFRONT
# ================================================

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS (must be in us-east-1)"
  type        = string
  # CloudFront requires certificates in us-east-1 regardless of region
}

variable "cloudfront_price_class" {
  description = "CloudFront price class — controls which edge locations are used"
  type        = string
  default     = "PriceClass_All"

  validation {
    condition = contains(
      ["PriceClass_100", "PriceClass_200", "PriceClass_All"],
      var.cloudfront_price_class
    )
    error_message = "Must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "cloudfront_default_ttl" {
  description = "Default cache TTL in seconds"
  type        = number
  default     = 3600
}

# ================================================
# MONITORING & ALERTING
# ================================================

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  sensitive   = true
}

variable "rds_cpu_alarm_threshold" {
  description = "RDS CPU % that triggers alarm"
  type        = number
  default     = 80
}

variable "ecs_cpu_alarm_threshold" {
  description = "ECS CPU % that triggers alarm"
  type        = number
  default     = 85
}

# ================================================
# COST MANAGEMENT
# ================================================

variable "monthly_budget_usd" {
  description = "Monthly AWS budget in USD — triggers alert at 80% and 100%"
  type        = number
  default     = 1000
}

variable "cost_anomaly_threshold_usd" {
  description = "Dollar amount that triggers a cost anomaly alert"
  type        = number
  default     = 100
}
