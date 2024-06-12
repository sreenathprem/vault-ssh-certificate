# Allow tokens to query themselves
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow tokens to renew themselves
path "auth/token/renew-self" {
    capabilities = ["update"]
}

# Allow tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["update"]
}

# Configure the actual secrets the token should have access to

# SSH Key Signing
path "ssh-client-signer/sign/*" {
    capabilities = ["read", "update"]
}

# Generating Azure Credentials
path "azure/creds/edu-app" {
  capabilities = [ "read" ]
}
