# Security Hardening Checklist
## AWS Production Environment — Fintech SaaS Platform

**Prepared by:** Ahmad Khorsandi Pour  
**Role:** Cloud Infrastructure Engineer  
**Last Updated:** October 2026  
**Environment:** AWS Production (Fintech SaaS — Oman)  
**Standard:** CIS Benchmark + AWS Foundations

> All client-specific identifiers, IPs, ARNs, 
> and credentials have been removed from this document.

---

## Section 1 — Linux Server Hardening (CIS Level 1 & 2)

### 1.1 SSH Configuration
```bash
# /etc/ssh/sshd_config — applied to all servers
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 60
X11Forwarding no
AllowTcpForwarding no
```

| Control | Status | Notes |
|---------|--------|-------|
| Root SSH login disabled | ✅ Applied | All servers |
| Password auth disabled | ✅ Applied | Key-only access |
| MaxAuthTries = 3 | ✅ Applied | Brute-force protection |
| SSH port changed | ✅ Applied | Non-default port |
| Fail2ban installed | ✅ Applied | 5 failures = 1hr ban |

### 1.2 Firewall (UFW)
```bash
# Rules applied on all EC2 instances
ufw default deny incoming
ufw default allow outgoing
ufw allow from [ALB-SG-CIDR] to any port 80
ufw allow from [ALB-SG-CIDR] to any port 443
ufw allow from [BASTION-IP] to any port [SSH-PORT]
ufw enable
```

| Control | Status |
|---------|--------|
| Default deny incoming | ✅ Applied |
| Only ALB traffic allowed on 80/443 | ✅ Applied |
| SSH restricted to bastion only | ✅ Applied |
| Outbound rules reviewed | ✅ Applied |

### 1.3 System Configuration
| Control | Status | Notes |
|---------|--------|-------|
| Unnecessary services disabled | ✅ Applied | Reviewed with systemctl |
| Automated security patches | ✅ Applied | unattended-upgrades |
| File permission audit | ✅ Applied | /etc/passwd, /etc/shadow |
| Cron job audit | ✅ Applied | All cron entries reviewed |
| System logging to CloudWatch | ✅ Applied | All servers |
| NTP synchronized | ✅ Applied | Consistent timestamps |
| Core dumps disabled | ✅ Applied | /etc/security/limits.conf |

---

## Section 2 — AWS Account Hardening (CIS Foundations)

### 2.1 IAM Configuration
| Control | Status | Notes |
|---------|--------|-------|
| MFA on root account | ✅ Applied | Hardware MFA |
| MFA on all IAM users | ✅ Applied | App-based MFA |
| Root account not used daily | ✅ Applied | Locked away |
| No inline IAM policies | ✅ Applied | Managed policies only |
| Least-privilege per service | ✅ Applied | Per ECS task role |
| Access key rotation | ✅ Applied | 90-day rotation |
| IAM password policy enforced | ✅ Applied | 14 char min, complexity |
| Unused credentials removed | ✅ Applied | Quarterly review |

### 2.2 S3 Security
| Control | Status | Notes |
|---------|--------|-------|
| Public access blocked (all buckets) | ✅ Applied | Account-level block |
| Bucket versioning enabled | ✅ Applied | Critical buckets |
| Server-side encryption | ✅ Applied | AES-256 |
| Access logging enabled | ✅ Applied | Logs → separate bucket |
| Lifecycle policies configured | ✅ Applied | Cost + compliance |

### 2.3 Logging & Monitoring
| Control | Status | Notes |
|---------|--------|-------|
| CloudTrail — all regions | ✅ Applied | Management events |
| CloudTrail log validation | ✅ Applied | Integrity verified |
| VPC flow logs enabled | ✅ Applied | All VPCs |
| AWS Config rules active | ✅ Applied | 12 managed rules |
| CloudWatch alarms configured | ✅ Applied | CPU, memory, errors |
| GuardDuty enabled | ✅ Applied | Threat detection |
| Security Hub enabled | ✅ Applied | Centralized findings |

### 2.4 Networking
| Control | Status | Notes |
|---------|--------|-------|
| No 0.0.0.0/0 on sensitive SGs | ✅ Applied | Reviewed all SGs |
| VPC properly segmented | ✅ Applied | Public/private subnets |
| NAT Gateway for private subnets | ✅ Applied | No direct internet |
| Network ACLs configured | ✅ Applied | Additional layer |
| Default VPC not used | ✅ Applied | Custom VPC only |

---

## Section 3 — WAF Configuration (OWASP Top 10)

### 3.1 Rules Applied
| Rule | Type | Action |
|------|------|--------|
| SQL Injection | AWS Managed | Block |
| Cross-Site Scripting (XSS) | AWS Managed | Block |
| Known bad inputs | AWS Managed | Block |
| Linux OS attacks | AWS Managed | Block |
| PHP application attacks | AWS Managed | Block |
| Rate limiting — per IP | Custom | Block (threshold) |
| Bad bot detection | AWS Managed | Block |
| Geo-restriction | Custom | Count/Block |
| Large body inspection | Custom | Block (>8KB) |
| IP reputation list | AWS Managed | Block |

### 3.2 WAF Monitoring
```
WAF Logs → CloudWatch Log Group
         → CloudWatch Metric Filters
         → CloudWatch Alarms
         → SNS → On-call alert
```

| Metric | Threshold | Action |
|--------|-----------|--------|
| Blocked requests spike | >500/min | Alert |
| SQLi attempts | >10/min | Alert + review |
| Rate limit triggers | >100/min | Alert |

---

## Section 4 — RDS Security

| Control | Status | Notes |
|---------|--------|-------|
| RDS in private subnet | ✅ Applied | No public access |
| Encryption at rest | ✅ Applied | AES-256 |
| Encryption in transit | ✅ Applied | SSL enforced |
| Automated backups | ✅ Applied | 7-day retention |
| Multi-AZ enabled | ✅ Applied | Auto failover |
| Read Replica configured | ✅ Applied | Read traffic separation |
| DB password rotation | ✅ Applied | Secrets Manager |
| Performance Insights | ✅ Applied | Query monitoring |
| Enhanced monitoring | ✅ Applied | OS-level metrics |

---

## Section 5 — Incident Response

### 5.1 Alert Levels
| Level | Trigger | Response Time |
|-------|---------|---------------|
| P1 — Critical | Service down / data breach | Immediate (24/7) |
| P2 — High | WAF spike / auth
