# Task 06 — Configuration Management Database Sync

## What I Built
An Azure Function with a Timer trigger that queries Resource Graph
daily and outputs a structured configuration item inventory —
simulating an automated CMDB sync integration.

## How It Works
The function runs on a daily schedule (0 0 * * *). It authenticates
to Azure using DefaultAzureCredential — no stored credentials. It
queries Resource Graph for all VMs, VNets, and SQL databases across
the subscription in a single API call. Each resource is transformed
into a structured configuration item with ci_class, name, location,
resource group, and tag attributes mapped to environment and cost centre.

## Why Resource Graph
Resource Graph queries across all subscriptions and resource types
in a single KQL-style query, returning results in seconds. The
alternative — looping through individual resource APIs — would make
hundreds of separate API calls and take minutes to complete.

## Why This Matters
Configuration management breaks down the moment the inventory is
manually maintained. Automated daily discovery via Resource Graph
keeps the configuration item inventory accurate without any manual
effort — ghost CIs and rogue resources are detected automatically.

## Skills Demonstrated
Azure Functions | Resource Graph | Python | Configuration Management |
Automated Asset Discovery | Timer Triggers | CMDB Integration
