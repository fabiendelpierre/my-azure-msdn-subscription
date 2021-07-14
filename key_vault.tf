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

resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.main.id

  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = var.my_aad_object_id
  key_permissions         = ["Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey"]
  secret_permissions      = ["Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"]
  certificate_permissions = []
  storage_permissions     = []
}

resource "azurerm_key_vault_access_policy" "tf" {
  key_vault_id = azurerm_key_vault.main.id

  tenant_id               = data.azurerm_client_config.current.tenant_id
  object_id               = var.terraform_aad_object_id
  key_permissions         = ["Create", "Delete", "Get", "List", "Purge", "Update"]
  secret_permissions      = ["Delete", "Get", "List", "Purge", "Set"]
  certificate_permissions = []
  storage_permissions     = []
}