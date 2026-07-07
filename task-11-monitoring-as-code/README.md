# Task 11 — Monitoring as Code

## What I Built
A complete monitoring stack deployed entirely via Terraform —
Log Analytics workspace, metric alert rules, action group with
email notifications, and an operations dashboard.

## What Was Deployed
- Log Analytics Workspace — central store for all logs and metrics
- Action Group — email notification to the ops team on alert
- Alert Rule: High CPU — fires when CPU exceeds 80% for 5 minutes
- Alert Rule: Low Memory — fires when available memory drops below 1GB
- Shared Dashboard — operations overview visible in the Azure portal

## Why Monitoring as Code
Manually configured alerts drift over time and cannot be version
controlled or peer reviewed. Defining monitoring in Terraform means
alert rules go through the same PR review process as infrastructure
changes — consistent, auditable, and reproducible across environments.

## Alert Design
Alerts are scoped to the resource group and target VM metrics.
Severity 2 (Warning) means the ops team is notified but no
automated remediation runs. In production, Severity 1 alerts
would trigger automated runbooks via Azure Automation.

## Skills Demonstrated
Azure Monitor | Log Analytics | Metric Alerts | Action Groups |
Terraform | Monitoring as Code | Observability | Dashboards
