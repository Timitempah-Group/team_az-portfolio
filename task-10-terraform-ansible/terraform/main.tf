terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
  }
  # Remote state stored in Azure Blob Storage
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatesenate"
    container_name       = "tfstate"
    key                  = "task10.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

variable "admin_password" {
  description = "VM admin password — set via terraform.tfvars"
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

resource "azurerm_resource_group" "task10" {
  name     = "rg-task10-demo"
  location = "uksouth"
  tags     = var.tags
}

# ── Networking ────────────────────────────────────────────────────
resource "azurerm_virtual_network" "task10" {
  name                = "vnet-task10"
  resource_group_name = azurerm_resource_group.task10.name
  location            = azurerm_resource_group.task10.location
  address_space       = ["10.20.0.0/16"]
  tags                = var.tags
}

resource "azurerm_subnet" "task10" {
  name                 = "snet-task10"
  resource_group_name  = azurerm_resource_group.task10.name
  virtual_network_name = azurerm_virtual_network.task10.name
  address_prefixes     = ["10.20.1.0/24"]
}

# Public IP — needed for Ansible to connect via SSH
resource "azurerm_public_ip" "task10" {
  name                = "pip-task10-vm"
  resource_group_name = azurerm_resource_group.task10.name
  location            = azurerm_resource_group.task10.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# NSG — allow SSH only, deny everything else
resource "azurerm_network_security_group" "task10" {
  name                = "nsg-task10"
  resource_group_name = azurerm_resource_group.task10.name
  location            = azurerm_resource_group.task10.location
  tags                = var.tags

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "task10" {
  name                = "nic-task10-vm"
  resource_group_name = azurerm_resource_group.task10.name
  location            = azurerm_resource_group.task10.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.task10.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.task10.id
  }
}

resource "azurerm_network_interface_security_group_association" "task10" {
  network_interface_id      = azurerm_network_interface.task10.id
  network_security_group_id = azurerm_network_security_group.task10.id
}

# ── Linux VM ──────────────────────────────────────────────────────
# Standard_D2ns_v6 requires Gen2 image — using 22_04-lts-gen2
resource "azurerm_linux_virtual_machine" "task10" {
  name                            = "vm-task10-demo"
  resource_group_name             = azurerm_resource_group.task10.name
  location                        = azurerm_resource_group.task10.location
  size                            = "Standard_D2ns_v6"
  admin_username                  = "azureuser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.task10.id]
  tags                            = var.tags

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Gen2 image required for Standard_D2ns_v6 VM size
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ── Outputs ───────────────────────────────────────────────────────
output "vm_public_ip" {
  value = azurerm_public_ip.task10.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.task10.name
}