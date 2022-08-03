# wireguard-ground-up
Building a Tailscale utility to create Azure endpoints.

This repository is being developed, and is not yet suitable for cloning.

Steps

1. Setup the Azure service principal.
  * https://learn.hashicorp.com/tutorials/terraform/azure-build?in=terraform/azure-get-started#create-a-service-principal
2. Create a Terraform Cloud account amnd workspace and create an API Key.
  * https://app.terraform.io/app/settings/tokens
3. Add these credentials to Github as:
  * AZURE_CLIENT_ID
  * AZURE_CLIENT_SECRET
  * AZURE_SUBSCRIPTION_ID
  * AZURE_TENANT_ID
  * TF_API_TOKEN
