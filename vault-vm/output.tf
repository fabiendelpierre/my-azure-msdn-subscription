output "vault_public_ip" {
  value = azurerm_public_ip.vault.ip_address
}