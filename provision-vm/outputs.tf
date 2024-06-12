output "vm_public_ip" {
  value = azurerm_linux_virtual_machine.example.public_ip_address
}

output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.ssh_key.private_key_openssh
  sensitive = true
}

output "signed_ssh_certificate" {
  value = vault_generic_endpoint.vault_signed_ssh_certs.write_data.signed_key
}