terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Stores this task's state separately from other tasks
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "gitops-pipeline.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# A simple resource group — the pipeline deploys this as proof
# that the GitOps workflow runs end to end
resource "azurerm_resource_group" "gitops_demo" {
  name     = "rg-gitops-demo"
  location = "uksouth"
  tags = {
    environment = "demo"
    cost-centre = "learning"
    owner       = "timmy-adeiza"
    managed-by  = "terraform"
  }
}

output "resource_group_name" {
  value = azurerm_resource_group.gitops_demo.name
}