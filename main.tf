terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
  required_version = ">=1.1.0"
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  alias           = "dev"
  client_id       = "c8a97064-c47b-4d26-8bce-a5ed245cf323"
  client_secret   = "D9l8Q~XOJksgpAnL2IhSrOJio1WZ9SeBtueOBdg2"
  tenant_id       = "cea297cb-9bde-428d-9a6e-48fa9c582ed6"
  subscription_id = "2a79f2da-f098-4c8a-8e2a-f426682b1eac"
}
resource "azurerm_resource_group" "example" {
  provider = azurerm.dev
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  provider            = azurerm.dev
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  provider             = azurerm.dev
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_public_ip" "example" {
  provider            = azurerm.dev
  name                = "example-publip"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "example" {
  provider            = azurerm.dev
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  provider                        = azurerm.dev
  name                            = "example-machine"
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = "Standard_DS2_v2"
  admin_username                  = "adminuser"
  admin_password                  = "Pa$$w0rd@1234!"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
