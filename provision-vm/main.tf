resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "vault_generic_endpoint" "vault_signed_ssh_certs" {
  data_json = jsonencode({
    public_key = tls_private_key.ssh_key.public_key_openssh
    valid_principals = "ubuntu"
  })
  path = "ssh-client-signer/sign/my-role"
  write_fields = [ "signed_key" ]
  disable_read = true
  ignore_absent_fields = true
  disable_delete = true
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
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
  name                  = "example-vm"
  resource_group_name   = azurerm_resource_group.example.name
  location              = azurerm_resource_group.example.location
  size                  = "Standard_B2s"
  admin_username        = "azureuser"
  network_interface_ids = [azurerm_network_interface.example.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

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

# Creating the signed SSH Key inside the Azure VM
locals {
  file_content = <<-EOF
    #!/bin/bash
    echo '${vault_generic_endpoint.vault_signed_ssh_certs.write_data.signed_key}' > /home/azureuser/.ssh/id_rsa.pub
    echo '${tls_private_key.ssh_key.private_key_openssh}' > /home/azureuser/.ssh/id_rsa
    chmod 400 /home/azureuser/.ssh/id_rsa
    chmod 400 /home/azureuser/.ssh/id_rsa.pub
    ssh -T -o StrictHostKeyChecking=no -i /home/azureuser/.ssh/id_rsa.pub -i /home/azureuser/.ssh/id_rsa ${var.management_server_username}@${var.management_server_ip} "touch /home/${var.management_server_username}/success"
    EOF
}

resource "azurerm_virtual_machine_extension" "vault_signed_ssh_keys" {
  name                 = "vault_signed_ssh_keys"
  virtual_machine_id   = azurerm_linux_virtual_machine.example.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.1"

  settings = jsonencode({
    commandToExecute = local.file_content
  })
}