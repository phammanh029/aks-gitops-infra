terraform {
  required_version = ">= 1.15.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# MODE A: use an existing virtual network and AKS subnet.
data "azurerm_virtual_network" "existing" {
  count               = var.create_vnet ? 0 : 1
  name                = var.vnet_name
  resource_group_name = var.vnet_resource_group_name != "" ? var.vnet_resource_group_name : var.resource_group_name
}

data "azurerm_subnet" "aks_existing" {
  count                = var.create_vnet ? 0 : 1
  name                 = var.aks_subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing[0].name
  resource_group_name  = data.azurerm_virtual_network.existing[0].resource_group_name
}

# MODE B: create a new virtual network and AKS subnet.
resource "azurerm_virtual_network" "this" {
  count               = var.create_vnet ? 1 : 0
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  count                = var.create_vnet ? 1 : 0
  name                 = var.aks_subnet_name
  resource_group_name  = azurerm_virtual_network.this[0].resource_group_name
  virtual_network_name = azurerm_virtual_network.this[0].name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 4, 0)]
}

locals {
  vnet_id             = var.create_vnet ? azurerm_virtual_network.this[0].id : data.azurerm_virtual_network.existing[0].id
  vnet_name           = var.create_vnet ? azurerm_virtual_network.this[0].name : data.azurerm_virtual_network.existing[0].name
  vnet_resource_group = var.create_vnet ? azurerm_virtual_network.this[0].resource_group_name : data.azurerm_virtual_network.existing[0].resource_group_name
  aks_subnet_id       = var.create_vnet ? azurerm_subnet.aks[0].id : data.azurerm_subnet.aks_existing[0].id
}

resource "azurerm_subnet" "alb" {
  name                 = var.alb_subnet_name
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [var.alb_subnet_cidr != "" ? var.alb_subnet_cidr : (var.create_vnet ? cidrsubnet(var.vnet_cidr, 12, 16) : "10.0.2.0/28")]

  delegation {
    name = "alb-delegation"

    service_delegation {
      name    = "Microsoft.ServiceNetworking/trafficControllers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}
