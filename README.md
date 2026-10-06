# aws-production-stack
AWS + Terraform + GitHub Actions Architecture

# AWS Production Stack — Fintech SaaS Platform

Cloud infrastructure I designed and own for a production 
fintech SaaS platform in Oman. Handles digital wallet 
services, festival ticketing, hotel and transport bookings.

Migrated 12 services from shared hosting to AWS with no 
service interruptions. During the Salalah Festival (Jun 2026), 
the stack carried 30,000+ transactions per hour across web, 
iOS, Android and POS simultaneously.

---

## Architecture Overview

```
USERS (Web · iOS · Android · POS)
         │
         ▼
    Route 53 (DNS)
         │
         ▼
   WAF (OWASP Top 10)
         │
         ▼
  CloudFront (CDN)
         │
         ▼
    ALB (Load Balancer)
    ┌────┴────┐
    ▼         ▼
ECS Fargate  ECS EC2
(Next.js)   (Laravel)
    │         │
    └────┬────┘
         │
    ┌────┴──────────┐
    ▼               ▼
RDS MySQL        Lambda
Multi-AZ +    (Event-driven)
Read Replica       │
                   ▼
              SQS → SNS
    
S3 (assets) → CloudFront
ECR (container registry)
Auto Scaling (all compute layers)

CI/CD:
GitHub → GitHub Actions → ECR → ECS (zero-downtime deploy)
```

---

## AWS Services Used

**Compute**
- EC2 — base instances
- ECS Fargate — containerized Next.js frontend
- ECS EC2 — Laravel backend (instance-level control)
- Lambda — event-driven processing
- Auto Scaling — absorbed 30,000+ TPS during peak

**Networking & Delivery**
- Route 53 — DNS management
- CloudFront — CDN and edge caching
- ALB — application load balancing
- VPC — network isolation

**Database & Storage**
- RDS MySQL — Multi-AZ + Read Replica
- S3 — static assets and backups
- ECR — container image registry

**Security**
- WAF — OWASP Top 10 ruleset
- IAM — least-privilege roles per service
- CIS Benchmark hardening (Linux Level 1/2 + AWS Foundations)

**Messaging**
- SQS — decoupled queue processing
- SNS — event notifications

**Operations**
- CloudWatch — monitoring and alerting
- AWS Backup — automated backup schedules
- AWS Budgets — cost alerting and right-sizing

---

## CI/CD Pipeline

```yaml
# Simplified flow — see .github/workflows/deploy.yml
Push to main branch
    → Build Docker image
    → Push to ECR
    → Update ECS service (rolling deploy)
    → Health check confirmation
```

Replaced a manual deployment process that was 
error-prone during high-traffic periods.

---

## Security Controls Applied

- CIS Benchmark Level 1 & 2 — all Linux servers
- AWS Foundations Benchmark — account-level
- SSH key-only authentication (password disabled)
- WAF rules: SQLi, XSS, rate limiting, bad bots
- S3 public access blocked on all buckets
- VPC flow logs enabled
- CloudTrail — all regions
- MFA enforced on all IAM users

See [`docs/security-hardening.md`](docs/security-hardening.md) 
for full checklist.

---

## Application Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js (ECS Fargate) |
| Backend | Laravel (ECS EC2) |
| Admin Panel | React |
| Database | MySQL on RDS |
| Cache | ElastiCache (Redis) |
| Container Registry | AWS ECR |

---

## Real-World Scale

During the Salalah Tourism Festival (Jun 2026):

- **30,000+ transactions/hour** at peak
- Simultaneous channels: web, iOS, Android, POS
- Transaction types: festival entry, bus passes, 
  parking, hotel bookings, food vouchers, concerts
- Auto Scaling absorbed the load without 
  manual intervention
- Zero downtime across all sales channels
- 24/7 SRE monitoring throughout the event

---

## Repository Structure

```
aws-production-stack/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Main deploy pipeline
│       └── rollback.yml        # Emergency rollback
├── terraform/
│   ├── main.tf                 # Core infrastructure
│   ├── variables.tf            # Configuration variables
│   ├── outputs.tf              # Stack outputs
│   └── modules/
│       ├── ec2/
│       ├── ecs/
│       ├── rds/
│       ├── waf/
│       └── networking/
├── docs/
│   ├── architecture.png        # Architecture diagram
│   └── security-hardening.md  # CIS checklist
└── README.md
```

---

## About

**Ahmad Khorsandi Pour**  
Cloud Infrastructure Engineer · DevOps · SRE  
📍 Muscat, Oman  
🔗 [linkedin.com/in/khorsandipour](https://linkedin.com/in/khorsandipour)  
📧 khorsandipour.a@gmail.com

---

*Note: This repository contains sanitized 
infrastructure patterns. All client-specific 
identifiers, credentials, and endpoints 
have been removed.*
