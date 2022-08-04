# Tailscale Creator
Build a Tailscale endpoint in Azure using Terraform.

This repository is being developed, and is not yet suitable for cloning.

Steps

1. Setup the Azure service principal.
  * https://learn.hashicorp.com/tutorials/terraform/azure-build?in=terraform/azure-get-started#create-a-service-principal
2. Create a Terraform Cloud account amnd workspace and create an API Key.
  * https://app.terraform.io/app/settings/tokens
3. Create a Tailscale account and auth key.
  * https://tailscale.com/kb/1085/auth-keys/?q=auth

4. Add these credentials to Github Actions secret as:
  * AZURE_CLIENT_ID
  * AZURE_CLIENT_SECRET
  * AZURE_SUBSCRIPTION_ID
  * AZURE_TENANT_ID
  * TF_API_TOKEN
  * TF_VAR_TAILSCALE_AUTHKEY
  * TF_VAR_VM_PASSWORD

5. Add ACL rules to the TailScale account configuration.

6. Build the image.

