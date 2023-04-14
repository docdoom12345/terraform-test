resource "azurerm_resource_group" "example" {
  provider = azurerm.dev
  name     = var.rg_name
  location = var.rg_location
}

resource "azurerm_virtual_network" "example" {
  provider            = azurerm.dev
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  provider             = azurerm.dev
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = var.subnet_address_prefix
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
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  size                            = var.size
  admin_username                  = "adminuser"
  disable_password_authentication = true
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "null_resource" "example" {
  connection {
    type        = "ssh"
    host        = azurerm_linux_virtual_machine.example.public_ip_address
    user        = "adminuser"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "C:\\Users\\docdo/.ssh/id_rsa.pub" #file location should be updated 
    destination = "/home/adminuser/.ssh/authorized_keys"
  }
}