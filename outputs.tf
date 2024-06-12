output "vm_public_ip" {
  value = module.provision-vm.vm_public_ip
}

output "public_key" {
  value = module.provision-vm.public_key
}

output "private_key" {
  value     = module.provision-vm.private_key
  sensitive = true
}

output "signed_ssh_certificate" {
  value = module.provision-vm.signed_ssh_certificate
  sensitive = true
}