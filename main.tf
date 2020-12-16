resource "azurerm_resource_group" "msdn_sandbox" {
  name = "${var.base_name}-rg"
  location = var.azure_region

  tags = local.tags
}