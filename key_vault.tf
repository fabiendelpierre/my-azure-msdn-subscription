resource "random_string" "kv" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_key_vault" "msdn_sandbox" {
  name                        = "${var.base_name}kv${random_string.random.result}"
  resource_group_name         = azurerm_resource_group.infra.name
  location                    = var.azure_region
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action             = "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }

  tags = local.tags
}

# resource "azurerm_key_vault_access_policy" "access_policies" {
#   for_each = var.authorized_entities

#   key_vault_id = azurerm_key_vault.main.id

#   tenant_id               = each.value.tenant_id
#   object_id               = each.value.object_id
#   key_permissions         = each.value.key_permissions
#   secret_permissions      = each.value.secret_permissions
#   certificate_permissions = each.value.certificate_permissions
#   storage_permissions     = each.value.storage_permissions
# }
