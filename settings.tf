terraform {
  required_version = "~> 1.0"

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

locals {
  tags = {
    git_url = "https://github.com/fabiendelpierre/my-azure-msdn-sandbox-infrastructure"
  }
}