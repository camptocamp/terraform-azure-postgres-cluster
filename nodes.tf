data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_network_interface" "this" {
  count               = var.instance_count
  name                = format("%s-%s", var.name, count.index)
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count               = var.instance_count
  name                = format("%s-%s", var.name, count.index)
  computer_name       = format("%s-%s.%s", var.name, count.index, var.domain_name)
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_F2"
  admin_username      = "terraform"
  network_interface_ids = [
    azurerm_network_interface.this[count.index].id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = var.public_ssh_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_dns_a_record" "nodes" {
  count               = var.instance_count

  name                = format("%s-%s", var.name, count.index)
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_network_interface.this[count.index].private_ip_address]
}

resource "azurerm_dns_a_record" "cluster" {
  name                = var.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name
  ttl                 = 30
  records             = [for res in azurerm_network_interface.this: res.private_ip_address]
}


#########
# Puppet

#module "puppet-node" {
#  source         = "git::https://github.com/camptocamp/terraform-puppet-node.git"
#  instance_count = var.instance_count
#
#  instances = [
#    for i in range(length(azurerm_linux_virtual_machine.this)) :
#    {
#      hostname = format("%s.%s", azurerm_linux_virtual_machine.this[i].name, var.domain)
#      connection = {
#        host        = lookup(var.connection, "host", exoscale_compute.this[i].ip_address)
#        private_key = lookup(var.connection, "private_key", null)
#      }
#    }
#  ]
#
#  server_address    = var.puppet != null ? lookup(var.puppet, "server_address", null) : null
#  server_port       = var.puppet != null ? lookup(var.puppet, "server_port", 443) : 443
#  ca_server_address = var.puppet != null ? lookup(var.puppet, "ca_server_address", null) : null
#  ca_server_port    = var.puppet != null ? lookup(var.puppet, "ca_server_port", 443) : 443
#  environment       = var.puppet != null ? lookup(var.puppet, "environment", null) : null
#  role              = var.puppet != null ? lookup(var.puppet, "role", null) : null
#  autosign_psk      = var.puppet != null ? lookup(var.puppet, "autosign_psk", null) : null
#
#  deps_on = null_resource.provisioner[*].id
#}
