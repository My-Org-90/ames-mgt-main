terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ------------------------------------------------------------
# Resource Group (Optional Creation)
# ------------------------------------------------------------

module "resource_group" {
  count   = var.resource_group_create ? 1 : 0
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  location = var.location
  name     = local.resource_names.resource_group_name
  tags     = var.tags
}

# ------------------------------------------------------------
# Virtual Network
# ------------------------------------------------------------

module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  resource_group_name = local.resource_group_name
  location            = var.location
  name                = local.resource_names.virtual_network_name
  address_space       = var.virtual_network_address_space
  subnets             = var.virtual_network_subnets
  tags                = var.tags
}

# ------------------------------------------------------------
# Virtual Machine
# ------------------------------------------------------------

module "virtual_machine" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.18.1"

  resource_group_name        = local.resource_group_name
  os_type                    = "linux"
  name                       = local.resource_names.virtual_machine_name
  sku_size                   = var.virtual_machine_sku
  location                   = var.location
  zone                       = "1"
  encryption_at_host_enabled = false

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  network_interfaces = {
    private = {
      name = local.resource_names.network_interface_name
      ip_configurations = {
        private = {
          name = local.resource_names.network_interface_name
          # Note: Ensure the key in var.virtual_network_subnets matches "example"
          # if your subnet is named differently in dev.tfvars, change "example" below.
          private_ip_subnet_resource_id = module.virtual_network.subnets["example"].resource_id
        }
      }
    }
  }

  tags = var.tags
}