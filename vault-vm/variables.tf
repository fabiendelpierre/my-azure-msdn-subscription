variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(any)
}

variable "base_name" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "nsg_name" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "my_ip_addresses" {
  type = list(string)
}

variable "key_vault_name" {
  type = string
}

variable "vm_size" {
  type    = string
  default = "Standard_B1ms"
}

variable "vm_admin_username" {
  type = string
}

variable "vm_admin_public_key" {
  type = string
}

# VM custom data variables
variable "vault_config_path" {
  type    = string
  default = "/etc/vault"
}

variable "vault_data_path" {
  type    = string
  default = "/var/lib/vault"
}

variable "vault_snapshots_path" {
  type    = string
  default = "/var/lib/vault_snapshots"
}

variable "vault_uid" {
  type    = string
  default = "9001"
}

variable "vault_gid" {
  type    = string
  default = "9001"
}

variable "vault_version" {
  type    = string
  default = "1.6.1"
}

variable "dns_validation_subscription_id" {
  type = string
}

variable "azure_tenant_id" {
  type = string
}

variable "azure_dns_client_id" {
  type = string
}

variable "azure_dns_client_secret" {
  type = string
}

variable "azure_files_endpoint" {
  type = string
}

variable "azure_files_share_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "storage_account_access_key" {
  type = string
}