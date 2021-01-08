output "vault_snapshot_azure_container_name" {
  value = module.storage_account.storage_container_name
}

output "vault_snapshot_azure_account_name" {
  value = module.storage_account.name
}

output "vault_snapshot_azure_account_key" {
  value     = module.storage_account.primary_access_key
  sensitive = true
}