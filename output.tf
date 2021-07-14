output "msdn_sandbox_vnet" {
  value = tomap({
    resource_group_name = azurerm_resource_group.infra.name
    name = azurerm_virtual_network.msdn_sandbox.name
    id = azurerm_virtual_network.msdn_sandbox.id
  })
}

output "msdn_sandbox_subnet1" {
  value = tomap({
    name = azurerm_subnet.msdn_sandbox1.name
    id = azurerm_subnet.msdn_sandbox1.id
    nsg_name = azurerm_network_security_group.msdn_sandbox1.name
    nsg_id = azurerm_network_security_group.msdn_sandbox1.id
  })
}

output "msdn_sandbox_key_vault" {
  value = tomap({
    name = azurerm_key_vault.msdn_sandbox.name
    id = azurerm_key_vault.msdn_sandbox.id
  })
}

output "msdn_sandbox_storage_account" {
  value = tomap({
    name = azurerm_storage_account.msdn_sandbox.name
    id = azurerm_storage_account.msdn_sandbox.id
  })
}