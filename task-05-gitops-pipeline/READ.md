# Task 05 — GitOps IaC Pipeline (GitHub Actions)

## What I Built
A 3-job GitHub Actions pipeline demonstrating GitOps governance:
validate and security scan → plan with saved artifact → manual
approval gate → apply using the saved plan.

## Pipeline Jobs

### Job 1 — Validate and Security Scan
Runs on every push and pull request. Includes:
- terraform fmt — enforces consistent code formatting
- terraform validate — catches syntax errors before any deployment
- tfsec — scans Terraform code for security misconfigurations
- Checkov — checks against 1000+ compliance policy rules

Both security scanners run in soft-fail mode initially — findings
are reported but do not block the pipeline. This is the audit-before-
enforce pattern: establish a baseline of existing findings first,
then switch to hard-fail for critical severity issues.

### Job 2 — Terraform Plan
Runs only on pushes to main. Generates a terraform plan and saves
it as a pipeline artifact. The saved plan is the exact contract of
what will change — every resource to be created, modified, or
destroyed is listed in it.

### Job 3 — Terraform Apply
Downloads the saved plan from Job 2 and applies it using
terraform apply tfplan. This guarantees that exactly what was
planned and approved is what gets deployed — not a re-plan that
could pick up unexpected changes.

The apply job is protected by a GitHub Environment with manual
approval — the pipeline pauses and waits for an approver to review
before anything is deployed to Azure.

## Key Design Decisions
No direct apply in production — every change goes through a PR,
security scan, plan review, and manual approval. The saved plan
artifact ensures the approver sees exactly what will be deployed.

Security scans use soft-fail initially following the audit-before-
enforce pattern — report first, enforce once the baseline is clean.

## Skills Demonstrated
GitHub Actions | Terraform | tfsec | Checkov | GitOps |
Manual Approval Gates | CI/CD Pipeline Design | IaC Security