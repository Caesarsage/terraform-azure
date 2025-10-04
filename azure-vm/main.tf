# This file is part of the Azure VM module.
# It defines the resources required to create a Virtual Machine in Azure.

resource "azurerm_public_ip" "main" {
  count = var.create_public_ip ? length(var.vm_configs) : 0

  name                = "${var.vm_configs[count.index].name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.public_ip_allocation
  sku                 = var.public_ip_sku

  tags = var.tags
}

resource "azurerm_network_interface" "main" {
  count = length(var.vm_configs)

  name                = "${var.vm_configs[count.index].name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.main[count.index].id : null
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  count = var.attach_network_security_group ? length(var.vm_configs) : 0

  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = var.network_security_group_id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [azurerm_network_interface.main]
}


resource "azurerm_linux_virtual_machine" "main" {
  count = length(var.vm_configs)

  name                = var.vm_configs[count.index].name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_configs[count.index].size
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = var.vm_configs[count.index].os_disk.caching
    storage_account_type = var.vm_configs[count.index].os_disk.storage_account_type
    disk_size_gb         = var.vm_configs[count.index].os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = var.vm_configs[count.index].source_image.publisher
    offer     = var.vm_configs[count.index].source_image.offer
    sku       = var.vm_configs[count.index].source_image.sku
    version   = var.vm_configs[count.index].source_image.version
  }

  identity {
    type = var.enable_system_assigned_identity ? "SystemAssigned" : null
  }

  custom_data = var.vm_configs[count.index].custom_data

  tags = merge(var.tags, var.vm_configs[count.index].tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "azurerm_managed_disk" "data_disks" {
  count = length(local.data_disks)

  name                 = "${local.data_disks[count.index].vm_name}-${local.data_disks[count.index].name}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = local.data_disks[count.index].storage_account_type
  create_option        = "Empty"
  disk_size_gb         = local.data_disks[count.index].disk_size_gb

  public_network_access_enabled = false

  disk_encryption_set_id = var.disk_encryption_set_id

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disks" {
  count = length(local.data_disks)

  managed_disk_id    = azurerm_managed_disk.data_disks[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[local.data_disks[count.index].vm_index].id
  lun                = local.data_disks[count.index].lun
  caching            = local.data_disks[count.index].caching
}

locals {
  data_disks = flatten([
    for vm_index, vm in var.vm_configs : [
      for disk_index, disk in coalesce(vm.data_disks, []) : {
        vm_name              = vm.name
        vm_index             = vm_index
        name                 = disk.name
        disk_size_gb         = disk.disk_size_gb
        storage_account_type = disk.storage_account_type
        lun                  = disk.lun
        caching              = disk.caching
      }
    ]
  ])
}
