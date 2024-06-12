terraform {
  cloud {
    organization = "sreeprem-org"

    workspaces {
      name = "vault-ssh-certificate"
    }
  }

  required_providers {
    vault = {
      source = "hashicorp/vault"
      version = "4.2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "vault" {
}

module "provision-vm" {
  source  = "app.terraform.io/sreeprem-org/provision-vm/azure"
  version = "0.0.5"

  management_server_ip = var.management_server_ip
  management_server_username = var.management_server_username
}