terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  # This tells Terraform to store its state file in the Azure storage account
  # you created in Part A. Replace the storage account name if you used a different one.
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "management-groups.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── Management Groups ──────────────────────────────────────────────────
# Management Groups sit ABOVE subscriptions.
# Policies assigned here cascade down to every subscription inside them.
resource "azurerm_management_group" "platform" {
  name         = "mg-platform"
  display_name = "Platform"
  # Hosts shared service subscriptions: Hub VNet, DNS, monitoring
}

resource "azurerm_management_group" "landing_zones" {
  name         = "mg-landing-zones"
  display_name = "Landing Zones"
  # Hosts all workload subscriptions
}

resource "azurerm_management_group" "production" {
  name                       = "mg-production"
  display_name               = "Production"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "non_production" {
  name                       = "mg-non-production"
  display_name               = "Non-Production"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "sandbox" {
  name         = "mg-sandbox"
  display_name = "Sandbox"
  # Isolated environment for experimentation
}