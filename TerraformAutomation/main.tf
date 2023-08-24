resource "azurerm_resource_group" "resourcegroup" {
  for_each = { for idx, data in local.csv_data : idx => data }
  name     = each.value.resourcegroup
  location = each.value.location
}

resource "azurerm_network_security_group" "nsg" {
  for_each = { for idx, data in local.csv_data : idx => data }
  name                = each.value.nsgName
  location            = each.value.location
  resource_group_name = azurerm_resource_group.resourcegroup[each.key].name

  dynamic "security_rule" {
    for_each = jsondecode(each.value.nsg_rules)

    content {
      name                       = security_rule.value.rdpRuleName
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.sourcePortRange
      destination_port_range     = security_rule.value.destinationPortRange
      source_address_prefix      = security_rule.value.sourceAddressPrefix
      destination_address_prefix = security_rule.value.destinationAddressPrefix
    }
  }
}

resource "azurerm_virtual_network" "vnetwork" {
  for_each = { for idx, data in local.csv_data : idx => data }
  name             = each.value.virtualNetworkName
  location         = azurerm_resource_group.resourcegroup[each.key].location
  resource_group_name = azurerm_resource_group.resourcegroup[each.key].name
  address_space    = [each.value.vnetAddressPrefixes]
}

resource "azurerm_subnet" "subnet" {
  for_each = { for idx, data in local.csv_data : idx => data }
  name               = each.value.subnetName
  resource_group_name = azurerm_resource_group.resourcegroup[each.key].name
  virtual_network_name = azurerm_virtual_network.vnetwork[each.key].name
  address_prefixes   = [each.value.snetAddressPrefixes]
}

resource "azurerm_network_interface" "network_interface" {
  for_each = { for idx, data in local.csv_data : idx => data }
  name              = each.value.nicName
  location          = azurerm_resource_group.resourcegroup[each.key].location
  resource_group_name = azurerm_resource_group.resourcegroup[each.key].name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = each.value.privateIPAllocationMethod
    private_ip_address            = each.value.privateIPv4Address
  }
}

resource "random_id" "storage_account_id" {
  for_each   = { for idx, data in local.csv_data : idx => data }
  byte_length = 8
  prefix     = "diag"
}

resource "tls_private_key" "ssh" {
  for_each = { for idx, data in local.csv_data : idx => data }
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_virtual_machine" "vm" {
  for_each = { for idx, data in local.csv_data : idx => data }

  name                 = each.value.virtualMachineName
  location             = each.value.location
  resource_group_name  = azurerm_resource_group.resourcegroup[each.key].name
  network_interface_ids = [azurerm_network_interface.network_interface[each.key].id]
  vm_size              = each.value.virtualMachineSize

  delete_os_disk_on_termination = true
  os_profile {
    computer_name  = each.value.virtualMachineName
    admin_username = each.value.adminUsername
    admin_password = each.value.adminPassword
  }

  dynamic "os_profile_windows_config" {
    for_each = each.value.os_type == "Windows" ? [1] : []

    content {
      provision_vm_agent = true
    }
  }

  dynamic "os_profile_linux_config" {
    for_each = each.value.os_type == "Linux" ? [1] : []

    content {
      disable_password_authentication = true

      ssh_keys {
        path     = "/home/${each.value.adminUsername}/.ssh/authorized_keys"
        key_data = tls_private_key.ssh[each.key].public_key_openssh
      }
    }
  }

  dynamic "storage_image_reference" {
    for_each = each.value.os_type == "Windows" || each.value.os_type == "Linux" ? [1] : []

    content {
      publisher = each.value.osImagePublisher
      offer     = each.value.osOffer
      sku       = each.value.osSKU
      version   = each.value.oSVersion
    }
  }

  dynamic "storage_os_disk" {
    for_each = each.value.os_type == "Windows" || each.value.os_type == "Linux" ? [1] : []

    content {
      name              = each.value.osDiskName
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = each.value.osDiskType
      os_type           = each.value.os_type == "Windows" ? "Windows" : "Linux"
    }
  }
}
/*
output "resource_group_names" {
  value = [for rg in azurerm_resource_group.resourcegroup : rg.value.name]
}

output "nsg_names" {
  value = [for nsg in azurerm_network_security_group.nsg : nsg.value.name]
}
*/