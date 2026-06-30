# Task 01 — Azure Landing Zone with IaC

## What I Built
A production-grade Azure Landing Zone using Terraform — the governance
foundation any enterprise organisation deploys at the start of a cloud
adoption journey.

## Architecture
- 3-level Management Group hierarchy: Platform / Landing Zones / Sandbox
- Azure Policy: mandatory tagging (environment, cost-centre, owner) — Deny effect
- Azure Policy: UK data residency enforcement — Deny effect
- Hub-Spoke VNet topology
- Azure Firewall (Basic SKU) inspecting all outbound and inter-spoke traffic
- Azure Bastion for secure RDP/SSH without public IPs on VMs
- User Defined Route (UDR) forcing all spoke traffic through the Firewall
- Private DNS Zone for Azure SQL private endpoints
- Terraform remote state in Azure Blob Storage with state locking

## Why It Matters
This represents the foundational governance layer every workload should
migrate into. Without this in place first, every subscription becomes a
governance and security mess within weeks of being created.

## Skills Demonstrated
Terraform | Remote State | Management Groups | Azure Policy |
Hub-Spoke Networking | Azure Firewall | Bastion | UDR | Private DNS