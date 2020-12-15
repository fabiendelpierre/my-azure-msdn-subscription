terraform {
  required_version = "~> 0.14"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.40"
    }
  }
}

# Use ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET
# env variables in TF Cloud to configure provider
provider "azurerm" {
  features {}
}