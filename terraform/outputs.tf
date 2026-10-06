# ================================================
# Outputs — AWS Production Stack
# Author: Ahmad Khorsandi Pour
# ================================================
# These values are displayed after terraform apply
# Sensitive outputs are marked — never logged
# ================================================

# ================================================
# NETWORKING
# ================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT Gateway)"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ECS, RDS)"
  value       = module.vpc.private_subnets
}

output "nat_gateway_ips" {
  description = "Elastic IPs for NAT Gateways — whitelist these on external APIs"
  value       = module.vpc.nat_public_ips
}

# ================================================
# LOAD BALANCER
# ================================================

output "alb_dns_name" {
  description = "ALB DNS name — point Route 53 or CloudFront origin here"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "ALB hosted zone ID — used for Route 53 alias records"
  value       = aws_lb.main.zone_id
}

# ================================================
# CLOUDFRONT
# ================================================

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed for cache invalidation"
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront hosted zone ID — used for Route 53 alias"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

# ================================================
# ECS
# ================================================

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

# ================================================
# RDS
# ================================================

output "rds_endpoint" {
  description = "RDS primary endpoint — use for write connections"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_replica_endpoint" {
  description = "RDS read replica endpoint — use for read connections"
  value       = aws_db_instance.replica.endpoint
  sensitive   = true
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_multi_az" {
  description = "Confirms Multi-AZ is enabled"
  value       = aws_db_instance.main.multi_az
}

# ================================================
# S3
# ================================================

output "assets_bucket_name" {
  description = "S3 assets bucket name"
  value       = aws_s3_bucket.assets.bucket
}

output "assets_bucket_arn" {
  description = "S3 assets bucket ARN"
  value       = aws_s3_bucket.assets.arn
}

output "logs_bucket_name" {
  description = "S3 logs bucket name"
  value       = aws_s3_bucket.logs.bucket
}

# ================================================
# WAF
# ================================================

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN — attach to ALB or CloudFront"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_capacity" {
  description = "WAF capacity units consumed"
  value       = aws_wafv2_web_acl.main.capacity
}

# ================================================
# SECURITY GROUPS
# ================================================

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS tasks security group ID"
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

# ================================================
# MONITORING
# ================================================

output "sns_alerts_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  value       = aws_sns_topic.alerts.arn
}

output "rds_cpu_alarm_name" {
  description = "CloudWatch alarm name for RDS CPU"
  value       = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
}

# ================================================
# SUMMARY — printed after terraform apply
# ================================================

output "deployment_summary" {
  description = "Quick reference after deployment"
  value = <<-EOT

    ================================================
    DEPLOYMENT COMPLETE
    ================================================
    Environment  : ${var.environment}
    Region       : ${var.aws_region}
    Project      : ${var.project_name}
    ------------------------------------------------
    CloudFront   : ${aws_cloudfront_distribution.main.domain_name}
    ALB          : ${aws_lb.main.dns_name}
    ECS Cluster  : ${aws_ecs_cluster.main.name}
    RDS          : [sensitive — run: terraform output rds_endpoint]
    ------------------------------------------------
    NAT IPs (whitelist these on external APIs):
    ${join("\n    ", module.vpc.nat_public_ips)}
    ================================================

  EOT
}
