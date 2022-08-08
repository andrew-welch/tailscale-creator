# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.8.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "= 3.2.0"
    }
  }

  required_version = ">= 1.1.0"

  cloud {
    organization = "882edn"
    workspaces {
      name = "pandawelch_tailscale-instances"
    }
  }

}

resource "random_string" "randomstr" {
  length           = 6
  special          = false
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

data "azurerm_client_config" "current_config" {
}

data "azurerm_public_ip_prefix" "owned-prefix" {
  name                = "prefixs-vpn"
  resource_group_name = "VPN-global"
}






resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_location
  tags = {
  	ManagedBy = "Terraform"
    
  }
}


# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "tailscale-VPN-vnet"
  address_space       = ["172.30.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "singlenet" {
  name                = "tailscale-VPN-single"
  address_prefixes    = ["172.30.1.0/24"]
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name=azurerm_virtual_network.vnet.name
}


resource "azurerm_network_security_group" "vpn-NSG" {
  name                = "tailscale_webserver"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "nsr-WG" {
  name                        = "tailscale-traffic"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Udp"
  source_port_range           = "*"
  destination_port_range      = "41641"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpn-NSG.name
}

resource "azurerm_network_security_rule" "nsr-SSH" {
  name                        = "temp-ssh"
  priority                    = 106
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.vpn-NSG.name
}

resource "azurerm_subnet_network_security_group_association" "nsg-sn-conn" {
  subnet_id      = azurerm_subnet.singlenet.id
  network_security_group_id = azurerm_network_security_group.vpn-NSG.id
}

resource "azurerm_linux_virtual_machine" "TS-VPN" {
  name                = "Tailscale-VPN-${random_string.randomstr.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "tailscale-vm-admin"
  network_interface_ids = [
    azurerm_network_interface.extnic.id,
  ]
  admin_password = var.VM_PASSWORD
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer = "debian-10"
    publisher = "debian"
    sku = "10"
    version = "latest"
  }

  identity {
    type = "SystemAssigned"
  }

  connection {
    type = "ssh"
    user = self.admin_username
    password = var.VM_PASSWORD
    host = self.public_ip_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install gnupg",
      
      "curl -fsSL https://pkgs.tailscale.com/stable/debian/buster.gpg | sudo apt-key add -",
      "curl -fsSL https://pkgs.tailscale.com/stable/debian/buster.list | sudo tee /etc/apt/sources.list.d/tailscale.list",

      "sudo apt-get update",
      "sudo apt-get -y upgrade",
      "sudo sysctl -w net.ipv4.ip_forward=1",
      "echo \"net.ipv4.ip_forward = 1\" | sudo tee -a  /etc/sysctl.conf",
      "sudo sysctl -p /etc/sysctl.conf",

      "sudo apt-get -y install tailscale",
      "sudo tailscale up --advertise-routes=172.30.0.0/16,168.63.129.16/32 --accept-dns=false --authkey ${var.TAILSCALE_AUTHKEY} --advertise-exit-node --advertise-tags=tag:server",

    ]
  }

}

resource "azurerm_public_ip" "pip" {
  name                = "TS-pip-${random_string.randomstr.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  public_ip_prefix_id = data.azurerm_public_ip_prefix.owned-prefix.id
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "extnic" {
  name                = "single-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  enable_ip_forwarding = true
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.singlenet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}


resource "azurerm_key_vault" "keyvault" {
  name                        = "tailscale-keyvault"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current_config.tenant_id

  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current_config.tenant_id
    object_id = azurerm_linux_virtual_machine.TS-VPN.identity.principal_id
    

    secret_permissions = [
      "Get", "List"
    ]

  }
}

resource "azurerm_key_vault_secret" "tailscale-authkey" {
  name         = "tailscale-authkey"
  value        = var.TAILSCALE_AUTHKEY
  key_vault_id = azurerm_key_vault.keyvault.id
}

#poke
#poke
#poke
#poke
#poke