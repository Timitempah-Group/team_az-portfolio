terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Remote state stored in Azure Blob Storage
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "task09.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Resource group for security scanning demo resources
resource "azurerm_resource_group" "task09" {
  name     = "rg-task09-demo"
  location = "uksouth"
  tags = {
    environment = "demo"
    cost-centre = "learning"
    owner       = "timmy-adeiza"
    managed-by  = "terraform"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.task09.name
}
