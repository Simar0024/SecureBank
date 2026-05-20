terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

resource "azurerm_resource_group" "sb_rg" {
  name     = "rg-securebank-prod"
  location = "Central India"
}

# --- NETWORKING BASELINE ---
resource "azurerm_virtual_network" "sb_vnet" {
  name                = "vnet-securebank"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.sb_rg.location
  resource_group_name = azurerm_resource_group.sb_rg.name
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-aks-compute"
  resource_group_name  = azurerm_resource_group.sb_rg.name
  virtual_network_name = azurerm_virtual_network.sb_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "kv_subnet" {
  name                 = "snet-keyvault-private"
  resource_group_name  = azurerm_resource_group.sb_rg.name
  virtual_network_name = azurerm_virtual_network.sb_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# --- ZERO-TRUST NETWORK SECURITY ---
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "nsg-aks"
  location            = azurerm_resource_group.sb_rg.location
  resource_group_name = azurerm_resource_group.sb_rg.name

  security_rule {
    name                       = "Allow_HTTPS_Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork" # Restrict to trusted ingress layer in real environment
    destination_address_prefix = "10.0.1.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks_assoc" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# --- DATA PROTECTION AT REST: KEY VAULT ---
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "sb_kv" {
  name                        = "kv-securebank-prod-0024" # Must be globally unique
  location                    = azurerm_resource_group.sb_rg.location
  resource_group_name         = azurerm_resource_group.sb_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard" # Premium SKU needed for Hardware Security Module (HSM) Customer Managed Keys
  purge_protection_enabled    = true
  public_network_access_enabled = false # Disables all public internet ingress channels

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }
}

# --- ISOLATION LAYER: PRIVATE ENDPOINT ---
resource "azurerm_private_endpoint" "kv_endpoint" {
  name                = "pe-keyvault"
  location            = azurerm_resource_group.sb_rg.location
  resource_group_name = azurerm_resource_group.sb_rg.name
  subnet_id           = azurerm_subnet.kv_subnet.id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.sb_kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
}