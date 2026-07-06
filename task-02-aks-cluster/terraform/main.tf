terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Stores this task's state separately from Task 1
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "aks-cluster.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      # Allow Terraform to delete the resource group even if it contains
      # resources that were auto-created by Azure (e.g. ContainerInsights)
      prevent_deletion_if_contains_resources = false
    }
  }
}

variable "location" { default = "uksouth" }
variable "tags" {
  default = {
    environment = "demo"
    cost-centre = "learning"
    owner       = "timmy-adeiza"
    managed-by  = "terraform"
  }
}

resource "azurerm_resource_group" "aks" {
  name     = "rg-aks-demo"
  location = var.location
  tags     = var.tags
}

# ── Log Analytics — feeds Container Insights ─────────────────────
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-aks-demo"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# ── Azure Container Registry — private, no admin credentials ─────
resource "azurerm_container_registry" "aks" {
  name                = "acrtimmydemoportfolio"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = var.tags
}

# ── VNet for AKS — Azure CNI requires a pre-created VNet ─────────
resource "azurerm_virtual_network" "aks" {
  name                = "vnet-aks"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  address_space       = ["10.10.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "aks_nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.10.1.0/24"]
}

# ── NAT Gateway — gives pods reliable outbound internet access ────
# Without this, Azure CNI pods rely on implicit SNAT through the
# load balancer which can silently fail in some subscriptions.
# This is the fix for the ImagePullBackOff / i/o timeout issue.
resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-gateway"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "aks" {
  name                = "nat-aks"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  sku_name            = "Standard"
  tags                = var.tags
}

# Associate the public IP with the NAT Gateway
resource "azurerm_nat_gateway_public_ip_association" "aks" {
  nat_gateway_id       = azurerm_nat_gateway.aks.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

# Associate the NAT Gateway with the AKS subnet so pods use it
resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks_nodes.id
  nat_gateway_id = azurerm_nat_gateway.aks.id
}

# ── AKS Cluster — production-grade configuration ─────────────────
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-demo-portfolio"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  dns_prefix          = "aks-demo-portfolio"
  kubernetes_version  = "1.34.8"

  # Entra ID RBAC — eliminates local Kubernetes user management
  azure_active_directory_role_based_access_control {
    managed            = true
    azure_rbac_enabled = true
  }

  # Workload Identity — Managed Identity per pod, no stored credentials
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  # System node pool — dedicated to Kubernetes system pods only.
  # Standard_D2ns_v6 used — B-series not available in this subscription
  default_node_pool {
    name                         = "system"
    node_count                   = 1
    vm_size                      = "Standard_D2ns_v6"
    vnet_subnet_id               = azurerm_subnet.aks_nodes.id
    enable_auto_scaling          = true
    min_count                    = 1
    max_count                    = 3
    only_critical_addons_enabled = true
  }

  # Azure CNI — pods get real VNet IPs (production standard)
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  # Container Insights — sends node/pod metrics to Log Analytics
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ── User node pool — application workloads only ──────────────────
# Kept separate from system pool so application pods never compete
# with Kubernetes system pods for resources
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D2ns_v6"
  vnet_subnet_id        = azurerm_subnet.aks_nodes.id
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 5
  tags                  = var.tags
}

# ── Grant AKS permission to pull from ACR — no credentials needed ─
# AcrPull on the kubelet identity means the nodes can pull images
# from ACR without any stored credentials or image pull secrets
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.aks.id
  skip_service_principal_aad_check = true
}

output "cluster_name" { value = azurerm_kubernetes_cluster.main.name }
output "resource_group" { value = azurerm_resource_group.aks.name }