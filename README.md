## Goal
This goal of this project is to demonstrate the SSH Key Signing (SSH Certificate) feature of HashiCorp Vault and how this can be combined with a TFE/TFC workflow

## Setup

<insert Solution Pic>

## SSH Certificate Engine in Vault

1. Enable the SSH Secret Engine
```
vault secrets enable -path=ssh-client-signer ssh
```

2. Configure the SSH Secret Engine. This command generates a new CA inside Vault. You could also do this with an existing CA
```
vault write ssh-client-signer/config/ca generate_signing_key=true
```

3. Create the Vault Role that is used by the TF Runs for signing the keys. The TTL of the certificates can be configured in this step.
```
vault write ssh-client-signer/roles/my-role -<<"EOH"
{
  "algorithm_signer": "rsa-sha2-256",
  "allow_user_certificates": true,
  "allowed_users": "*",
  "allowed_extensions": "permit-pty,permit-port-forwarding",
  "default_extensions": {
    "permit-pty": ""
  },
  "key_type": "ca",
  "default_user": "azureuser",
  "ttl": "2m0s"
}
EOH
```

4. Assign a policy to the role, so that the role is allowed to sign keys.
```
vault policy write tfc-policy tfc-policy.hcl
```

More details here -> [Signed SSH Certificates](https://developer.hashicorp.com/vault/docs/secrets/ssh/signed-ssh-certificates)

## Authenticating between Vault and TFE

The TF Runs in a TFE workspace would need to authenticate with Vault to sign the SSH Keys. Rather than statically providing a Vault Token or a username and password, we could leverage the inbuilt OpenID connect integration between Vault and TFE. In this the Vault TF provider is able to sign the keys automatically

More details here -> [Dynamic Credentials with the Vault Provider](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/vault-configuration)

## Authenticating between Vault and Azure

In this demo, I am provisioning a Azure Linux VM to talk to the Management Server. For this purpose my TF runs should authenticate with Azure. Here again I am leveraging the OIDC integration between TFE and Azure. 

More details here -> [Dynamic Credentials with the Azure Provider](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/azure-configuration)

## Setting up the Management Server

The Management Server needs to be setup to trust the CA which is used by Vault. This can configured in the sshd_config inside Vault

1. Fetch the public key of the CA from Vault
```
vault read -field=public_key ssh-client-signer/config/ca > /etc/ssh/trusted-user-ca-keys.pem
```
2. Copy this key to the Management Server
3. Edit the sshd_config to trust this public key
```
# /etc/ssh/sshd_config
# ...
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pem
```
4. In my case, I also had to add the additional parameters to the sshd_config
```
PubkeyAcceptedAlgorithms +ssh-rsa-cert-v01@openssh.com
HostkeyAlgorithms +ssh-rsa-cert-v01@openssh.com
```
