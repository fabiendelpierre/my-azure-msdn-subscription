resource "azurerm_resource_group" "aks" {
  name     = "${var.base_name}-aks"
  location = var.azure_region

  tags = local.tags
}

resource "azurerm_user_assigned_identity" "aks" {
  resource_group_name = azurerm_resource_group.aks.name
  location            = var.azure_region
  name                = "${var.base_name}-aks-uai"
  tags                = local.tags
}

resource "azurerm_role_assignment" "aks_subnet_network_contributor" {
  scope                = azurerm_subnet.msdn_sandbox1.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

resource "azurerm_role_assignment" "aks_route_table_network_contributor" {
  scope                = azurerm_route_table.msdn_sandbox.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}