# Task 10 — VM Provisioning with Terraform and Ansible

## What I Built
A Linux VM provisioned with Terraform and configured post-deployment
with Ansible — demonstrating the standard IaC + configuration
management pattern used in enterprise cloud delivery.

## How It Works
Terraform provisions the infrastructure: resource group, VNet, subnet,
NSG (SSH only), public IP, network interface, and the Ubuntu 22.04 VM.
Once Terraform completes and outputs the public IP, Ansible connects
via SSH and handles post-provisioning configuration.

## Ansible Playbook Steps
1. Update apt package cache
2. Install Nginx web server
3. Start and enable Nginx as a systemd service
4. Deploy a custom health check page
5. Verify Nginx is running and print status

## Why Terraform + Ansible Together
Terraform is excellent at provisioning infrastructure but is not
designed for OS-level configuration. Ansible fills that gap —
it connects to the running VM and configures the OS, installs
packages, and deploys application config without needing an agent
installed on the VM. Together they cover the full stack from
infrastructure to application configuration.

## Play Recap Result
ok=7  changed=4  unreachable=0  failed=0

## Skills Demonstrated
Terraform | Ansible | Linux VM | Nginx | NSG | IaC |
Configuration Management | Post-Provisioning Automation
