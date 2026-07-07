# Task 09 — CI/CD Pipeline with Integrated Security Scanning

## What I Built
A multi-layer security scanning pipeline demonstrating shift-left
security — catching vulnerabilities at the earliest possible point
in the delivery process before anything reaches production.

## Scanning Layers

### Layer 1 — SAST (SonarCloud)
Static Application Security Testing on the Python application code.
Catches bugs, vulnerabilities, and code smells before the build
starts. Runs on every pull request so developers see findings during
code review, not after deployment.

### Layer 2 — IaC Security (tfsec + Checkov)
tfsec scans Terraform code for security misconfigurations — things
like storage accounts with public access enabled or VMs without disk
encryption. Checkov checks against 1000+ compliance policy rules
across Terraform, Docker, and Kubernetes manifests.

### Layer 3 — Container Scanning (Trivy)
Trivy scans application dependencies for known CVEs. Catches
vulnerable library versions before they are deployed to production.

## Audit Before Enforce Pattern
All scanners run with soft-fail initially — findings are reported
but do not block the pipeline. This establishes a baseline of
existing findings first. Once triaged, critical severity findings
are switched to hard-fail to actively block vulnerable code.

## Skills Demonstrated
SonarCloud | tfsec | Checkov | Trivy | GitHub Actions |
Shift-Left Security | SAST | IaC Security | Container Scanning
