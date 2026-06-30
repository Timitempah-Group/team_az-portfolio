terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Stores Terraform state in the Azure storage account created in Part A
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "policy.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# ── Policy Definitions ─────────────────────────────────────────────────

# Custom policy: denies resource creation if mandatory tags are missing
resource "azurerm_policy_definition" "require_tags" {
  name         = "require-mandatory-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Require mandatory tags: environment, cost-centre, owner"

  # Must be defined at Management Group level to be assigned to a Management Group
  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-non-production"

  # Reads the rule from the JSON file in the definitions folder
  policy_rule = file("${path.module}/definitions/require-tags.json")
}

# Custom policy: denies resource creation outside UK South, UK West, or global
resource "azurerm_policy_definition" "uk_location" {
  name         = "enforce-uk-location"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Enforce UK data residency — deny resources outside UK regions"

  # Must be defined at Management Group level to be assigned to a Management Group
  management_group_id = "/providers/Microsoft.Management/managementGroups/mg-non-production"

  # Reads the rule from the JSON file in the definitions folder
  policy_rule = file("${path.module}/definitions/uk-location.json")
}

# ── Policy Assignments ─────────────────────────────────────────────────
# Assigns the tag policy to the Non-Production Management Group first
# Safer than assigning to Production on first run — validate here first
resource "azurerm_management_group_policy_assignment" "tags_nonprod" {
  name                 = "assign-mandatory-tags"
  display_name         = "Enforce mandatory tagging"
  policy_definition_id = azurerm_policy_definition.require_tags.id
  management_group_id  = "/providers/Microsoft.Management/managementGroups/mg-non-production"
}