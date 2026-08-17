# Azure Portfolio

## About

Eleven builds, one rule: if it's not running in a real Azure subscription, it doesn't
count. Each task tackles a genuine infrastructure problem — landing zones, container
orchestration, disaster recovery, cost governance — the way a client engagement
actually demands it.

Infrastructure for each task is torn down after review to keep this a zero-cost
portfolio rather than a running bill. The Terraform and Ansible in every folder is
the real, applied code — proof lives in the commit history and the screenshots
captured during each deployment. The CI/CD pipelines in Tasks 05 and 08 are
intentionally disabled for the same reason: they're accurate, working GitOps
pipelines, but with no live infrastructure left to target after teardown, they're
parked rather than left to fail on every push.

## Tasks

| # | Task | Skills |
|---|------|--------|
| 01 | Azure Landing Zone | Terraform, Management Groups, Azure Policy, Hub-Spoke |
| 02 | AKS Production Cluster | AKS, Azure CNI, Workload Identity, HPA |
| 03 | Disaster Recovery | ASR, SQL Geo-Replication, Traffic Manager |
| 04 | FinOps Dashboard | Cost Management, Azure Workbooks, Budgets |
| 05 | GitOps Pipeline | GitHub Actions, Terraform, tfsec, infracost |
| 06 | CMDB Sync | Azure Functions, Resource Graph API |
| 07 | Security Posture | Defender for Cloud, Secure Score, ADRs |
| 08 | Azure DevOps Pipeline | Azure DevOps, Terraform, Approval Gates |
| 09 | CI/CD Security Scanning | SonarCloud, Trivy, Checkov |
| 10 | Terraform + Ansible | VM provisioning, OS hardening, Nginx |
| 11 | Monitoring as Code | Azure Monitor, Log Analytics, KQL alerts |
