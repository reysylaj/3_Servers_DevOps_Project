# Specify the Terraform version and required providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0"
}

provider "azurerm" {
  features {
    resource_group {}
  }

  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Create a Resource Group
resource "azurerm_resource_group" "devops-nsg" {
  name     = "devops-nsg-resources"
  location = var.location
}

# Create a Virtual Network
resource "azurerm_virtual_network" "devops-nsg" {
  name                = "devops-nsg-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.devops-nsg.location
  resource_group_name = azurerm_resource_group.devops-nsg.name
}

# Create a Public IP
resource "azurerm_public_ip" "devops-nsg" {
  name                = "devops-nsg-public-ip"
  location            = azurerm_resource_group.devops-nsg.location
  resource_group_name = azurerm_resource_group.devops-nsg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "devops-nsg" {
  name                = "devops-nsg-nsg"
  location            = azurerm_resource_group.devops-nsg.location
  resource_group_name = azurerm_resource_group.devops-nsg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 80
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create a Subnet
resource "azurerm_subnet" "devops-nsg" {
  name                 = "devops-nsg-subnet"
  resource_group_name  = azurerm_resource_group.devops-nsg.name
  virtual_network_name = azurerm_virtual_network.devops-nsg.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Associate the NSG with the Subnet
resource "azurerm_subnet_network_security_group_association" "devops-nsg" {
  subnet_id                 = azurerm_subnet.devops-nsg.id
  network_security_group_id = azurerm_network_security_group.devops-nsg.id
}

# Create a Network Interface
resource "azurerm_network_interface" "devops-nsg" {
  name                = "devops-nsg-nic"
  location            = azurerm_resource_group.devops-nsg.location
  resource_group_name = azurerm_resource_group.devops-nsg.name

  ip_configuration {
    name                          = "devops-nsg-ip-config"
    subnet_id                     = azurerm_subnet.devops-nsg.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.devops-nsg.id
  }
}

# Create a Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "devops-nsg" {
  name                            = "devops-nsg-vm"
  resource_group_name             = azurerm_resource_group.devops-nsg.name
  location                        = azurerm_resource_group.devops-nsg.location
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  network_interface_ids           = [azurerm_network_interface.devops-nsg.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("vm.pub") # Replace with the path to your SSH public key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "19_04-gen2"
    version   = "latest"
  }
}

# Output the public IP address of the VM
output "public_ip" {
  value       = azurerm_public_ip.devops-nsg.ip_address
  description = "The public IP address of the virtual machine"
}
