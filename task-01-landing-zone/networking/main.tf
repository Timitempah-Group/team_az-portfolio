terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Stores Terraform state in the Azure storage account created in Part A
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "networking.tfstate"
  }
}

provider "azurerm" {
  features {}
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

resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-networking"
  location = var.location
  tags     = var.tags
}

# ── Hub VNet ────────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# IMPORTANT: These subnet names are FIXED by Azure.
# They must be spelled exactly like this — do not change them.
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/26"]
}

# Management subnet — required for Basic SKU Firewall.
# Basic SKU Firewall handles management traffic separately from data traffic,
# so it needs its own dedicated subnet and public IP.
resource "azurerm_subnet" "firewall_management" {
  name                 = "AzureFirewallManagementSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.3.0/26"]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/27"]
}

# ── Azure Firewall ───────────────────────────────────────────────────────
resource "azurerm_public_ip" "firewall" {
  name                = "pip-firewall"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Public IP for the Firewall's management interface — required for Basic SKU
resource "azurerm_public_ip" "firewall_management" {
  name                = "pip-firewall-mgmt"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_firewall" "hub" {
  name                = "fw-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Basic"
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  # Required for Basic SKU Firewall — management traffic uses this separate interface
  management_ip_configuration {
    name                 = "management"
    subnet_id            = azurerm_subnet.firewall_management.id
    public_ip_address_id = azurerm_public_ip.firewall_management.id
  }
}

# ── Public IP for Bastion ────────────────────────────────────────────────
resource "azurerm_public_ip" "bastion" {
  name                = "pip-bastion"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_bastion_host" "hub" {
  name                = "bastion-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

# ── Spoke VNet ──────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-workload"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = ["10.1.0.0/16"]
  tags                = var.tags
}

# ── VNet Peering (both directions required) ──────────────────────────────
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

# ── Route Table: force spoke traffic through Firewall ────────────────────
# Without this UDR, traffic would bypass the Firewall completely.
# The 0.0.0.0/0 route means: send ALL traffic to the Firewall first.
resource "azurerm_route_table" "spoke" {
  name                = "rt-spoke-to-firewall"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  tags                = var.tags
}

resource "azurerm_route" "default_to_firewall" {
  name                   = "route-all-to-firewall"
  resource_group_name    = azurerm_resource_group.hub.name
  route_table_name       = azurerm_route_table.spoke.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  # Points all traffic to the Firewall's private IP address
  next_hop_in_ip_address = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}

# ── Private DNS Zone ────────────────────────────────────────────────────
# This zone lets resources inside the VNet resolve Azure SQL private endpoints
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql_hub" {
  name                  = "link-sql-dns-to-hub"
  resource_group_name   = azurerm_resource_group.hub.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
}

# ── Outputs ─────────────────────────────────────────────────────────────
output "hub_vnet_id" {
  value = azurerm_virtual_network.hub.id
}

output "firewall_private_ip" {
  value = azurerm_firewall.hub.ip_configuration[0].private_ip_address
}