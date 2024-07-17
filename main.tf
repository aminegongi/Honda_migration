terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.47.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Honda" {
  name     = "Honda"
  location = "West US"
}

resource "azurerm_virtual_network" "vnet-honda" {
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.Honda.location
  name                = "vnet-honda"
  resource_group_name = azurerm_resource_group.Honda.name
  depends_on = [
    azurerm_resource_group.Honda,
  ]
}

resource "azurerm_public_ip" "VM-AD-pip" {
  name                = "VM-AD-pip"
  resource_group_name = azurerm_resource_group.Honda.name
  location            = azurerm_resource_group.Honda.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "VM-ERP-ip" {
  name                = "VM-ERP-ip"
  resource_group_name = azurerm_resource_group.Honda.name
  location            = azurerm_resource_group.Honda.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "VM-INCADEA-ip" {
  name                = "VM-INCADEA-ip"
  resource_group_name = azurerm_resource_group.Honda.name
  location            = azurerm_resource_group.Honda.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "PIP-VNGW-01" {
  name                = "PIP-VNGW-01"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name
  allocation_method   = "Dynamic"
}

resource "azurerm_subnet" "subnet-honda" {
  address_prefixes     = ["10.0.0.0/26"]
  name                 = "subnet-honda"
  resource_group_name  = azurerm_resource_group.Honda.name
  virtual_network_name = azurerm_virtual_network.vnet-honda.name
  service_endpoints    = ["Microsoft.KeyVault"]
  depends_on = [
    azurerm_virtual_network.vnet-honda,
  ]
}

resource "azurerm_subnet" "gateway-subnet" {
  address_prefixes     = ["10.0.0.64/26"]
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.Honda.name
  virtual_network_name = azurerm_virtual_network.vnet-honda.name
}

resource "azurerm_virtual_network_gateway" "VNGW-HONDA-01" {
  name                = "VNGW-HONDA-01"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.PIP-VNGW-01.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway-subnet.id
  }

}


resource "azurerm_local_network_gateway" "LocalNetworkHonda" {
  name                = "LocalNetworkHonda"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name
  gateway_address     = "203.0.113.1"
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_virtual_network_gateway_connection" "AzuretoFortigate" {
  name                = "AzuretoFortigate"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.VNGW-HONDA-01.id
  local_network_gateway_id   = azurerm_local_network_gateway.LocalNetworkHonda.id

}

resource "azurerm_windows_virtual_machine" "VM-AD" {
  name                  = "VM-AD"
  location              = azurerm_resource_group.Honda.location
  resource_group_name   = azurerm_resource_group.Honda.name
  network_interface_ids = [azurerm_network_interface.VM-AD_nic.id]
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = "P@$$w0rd1234!"
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "VM-AD_nic" {
  name                = "vm-ad369"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-honda.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.VM-AD-pip.id
  }
}

resource "azurerm_windows_virtual_machine" "VM-ERP" {
  name                  = "VM-ERP"
  location              = azurerm_resource_group.Honda.location
  resource_group_name   = azurerm_resource_group.Honda.name
  network_interface_ids = [azurerm_network_interface.VM-ERP_nic.id]
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = "P@$$w0rd1234!"
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "VM-ERP_nic" {
  name                = "vm-erp407"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-honda.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.VM-ERP-ip.id
  }
}

resource "azurerm_windows_virtual_machine" "VM-INCADEA" {
  name                  = "VM-INCADE"
  location              = azurerm_resource_group.Honda.location
  resource_group_name   = azurerm_resource_group.Honda.name
  network_interface_ids = [azurerm_network_interface.VM-INCADE_nic.id]
  size                  = "Standard_F2"
  admin_username        = "adminuser"
  admin_password        = "P@$$w0rd1234!"
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "VM-INCADE_nic" {
  name                = "vm-incade138"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-honda.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.VM-INCADEA-ip.id
  }
}

resource "azurerm_automation_account" "Automation-account-01" {
  name                = "Automation-account-01"
  location            = azurerm_resource_group.Honda.location
  resource_group_name = azurerm_resource_group.Honda.name
  sku_name            = "Basic"

}