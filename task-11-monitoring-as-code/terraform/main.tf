terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "task11.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variable "tags" {
  default = {
    environment = "demo"
    cost-centre = "learning"
    owner       = "timmy-adeiza"
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "task11" {
  name     = "rg-task11-monitoring"
  location = "uksouth"
  tags     = var.tags
}

# ── Log Analytics Workspace ───────────────────────────────────────
# Central store for all logs and metrics
resource "azurerm_log_analytics_workspace" "task11" {
  name                = "law-task11-monitoring"
  resource_group_name = azurerm_resource_group.task11.name
  location            = azurerm_resource_group.task11.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ── Action Group — defines WHO gets notified and HOW ─────────────
resource "azurerm_monitor_action_group" "task11" {
  name                = "ag-task11-ops-team"
  resource_group_name = azurerm_resource_group.task11.name
  short_name          = "opsteam"
  tags                = var.tags

  email_receiver {
    name          = "ops-email"
    email_address = "timitempahgroup@outlook.com"
  }
}

# ── Alert Rule 1: High CPU ────────────────────────────────────────
# Fires when average CPU exceeds 80% for 5 minutes
# target_resource_type required when scoping to a resource group
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "alert-high-cpu"
  resource_group_name = azurerm_resource_group.task11.name
  scopes              = [azurerm_resource_group.task11.id]
  description         = "Alert when CPU exceeds 80% for 5 minutes"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = "uksouth"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.task11.id
  }
}

# ── Alert Rule 2: Low Memory ──────────────────────────────────────
# Fires when available memory drops below 1GB
resource "azurerm_monitor_metric_alert" "low_memory" {
  name                = "alert-low-memory"
  resource_group_name = azurerm_resource_group.task11.name
  scopes              = [azurerm_resource_group.task11.id]
  description         = "Alert when available memory drops below 1GB"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  target_resource_type     = "Microsoft.Compute/virtualMachines"
  target_resource_location = "uksouth"
  tags                = var.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1073741824
  }

  action {
    action_group_id = azurerm_monitor_action_group.task11.id
  }
}

# ── Azure Monitor Dashboard ───────────────────────────────────────
resource "azurerm_dashboard" "task11" {
  name                = "dashboard-task11-ops"
  resource_group_name = azurerm_resource_group.task11.name
  location            = azurerm_resource_group.task11.location
  tags                = var.tags

  dashboard_properties = jsonencode({
    lenses = {
      "0" = {
        order = 0
        parts = {
          "0" = {
            position = {
              x       = 0
              y       = 0
              rowSpan = 4
              colSpan = 6
            }
            metadata = {
              inputs = []
              type   = "Extension/HubsExtension/PartType/MarkdownPart"
              settings = {
                content = {
                  settings = {
                    content  = "## Operations Dashboard\nMonitoring alerts and Log Analytics workspace for portfolio Task 11."
                    title    = "Task 11 — Monitoring as Code"
                    subtitle = "Azure Monitor | Log Analytics | Alerts"
                  }
                }
              }
            }
          }
        }
      }
    }
    metadata = {
      model = {}
    }
  })
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.task11.id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.task11.id
}
