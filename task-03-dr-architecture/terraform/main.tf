terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Stores this task's state separately from other tasks
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "dr-architecture.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      # Allow Terraform to delete resource groups even if they contain
      # resources auto-created by Azure
      prevent_deletion_if_contains_resources = false
    }
  }
}

variable "sql_password" {
  description = "SQL admin password — set via terraform.tfvars, never commit this file"
  sensitive   = true
}

variable "tags" {
  default = {
    environment = "demo"
    cost-centre = "learning"
    owner       = "timmy-adeiza"
    managed-by  = "terraform"
  }
}

# ── Primary region: UK South ──────────────────────────────────────
resource "azurerm_resource_group" "primary" {
  name     = "rg-dr-primary"
  location = "uksouth"
  tags     = var.tags
}

resource "azurerm_mssql_server" "primary" {
  name                         = "sql-dr-demo-primary-timmy"
  resource_group_name          = azurerm_resource_group.primary.name
  location                     = azurerm_resource_group.primary.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_password
  tags                         = var.tags
}

resource "azurerm_mssql_database" "primary" {
  name      = "db-app"
  server_id = azurerm_mssql_server.primary.id
  # S0 is the cheapest tier that supports geo-replication
  sku_name  = "S0"
  tags      = var.tags
}

# ── Secondary region: UK West ─────────────────────────────────────
resource "azurerm_resource_group" "secondary" {
  name     = "rg-dr-secondary"
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_mssql_server" "secondary" {
  name                         = "sql-dr-demo-secondary-timmy"
  resource_group_name          = azurerm_resource_group.secondary.name
  location                     = azurerm_resource_group.secondary.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_password
  tags                         = var.tags
}

# ── SQL Failover Group — automatic failover between regions ───────
# Grace period of 60 minutes means Azure waits 60 mins before
# automatically failing over — avoids failing over on a short blip
resource "azurerm_mssql_failover_group" "dr" {
  name      = "fog-dr-demo-timmy"
  server_id = azurerm_mssql_server.primary.id
  databases = [azurerm_mssql_database.primary.id]

  partner_server {
    id = azurerm_mssql_server.secondary.id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}

# ── Outputs ───────────────────────────────────────────────────────
output "primary_sql_server" {
  value = azurerm_mssql_server.primary.fully_qualified_domain_name
}

output "secondary_sql_server" {
  value = azurerm_mssql_server.secondary.fully_qualified_domain_name
}

output "failover_group_name" {
  value = azurerm_mssql_failover_group.dr.name
}