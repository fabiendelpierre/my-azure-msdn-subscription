resource "azurerm_resource_group" "msdn_sandbox" {
  name      = "${var.base_name}-rg"
  location  = var.azure_region

  tags = local.tags
}

resource "azurerm_dns_zone" "msdn_sandbox" {
  name                = var.sandbox_domain_name
  resource_group_name = azurerm_resource_group.msdn_sandbox.name

  tags = local.tags
}