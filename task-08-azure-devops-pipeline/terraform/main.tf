terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  backend "azurerm" {
    # These values are injected by the pipeline from the Variable Group
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "task08.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# A simple resource group — the pipeline deploys this as proof
# that the Azure DevOps GitOps workflow runs end to end
resource "azurerm_resource_group" "task08" {
  name     = "rg-task08-demo"
  location = "uksouth"
  tags = {
    environment = "demo"
    cost-centre = "learning"
    owner       = "timmy-adeiza"
    managed-by  = "terraform"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.task08.name
}