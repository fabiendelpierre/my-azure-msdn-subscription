resource "azurerm_storage_account" "msdn_sandbox" {
  name                     = "${var.base_name}sa${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.infra.name
  location                 = var.azure_region
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Cool"
  min_tls_version          = "TLS1_2"

  lifecycle {
    ignore_changes = [
      queue_properties,
      resource_group_name,
      location,
      account_tier,
      account_kind,
      is_hns_enabled
    ]
  }

  tags = local.tags
}

resource "azurerm_storage_account_network_rules" "msdn_sandbox" {
  resource_group_name  = azurerm_resource_group.infra.name
  storage_account_name = azurerm_storage_account.msdn_sandbox.name

  default_action             = "Allow"
  bypass                     = ["AzureServices", "Logging", "Metrics"]
  ip_rules                   = []
  virtual_network_subnet_ids = []
}