variable "base_name" {
  type = string
}

variable "azure_region" {
  type = string
}

variable "sandbox_domain_name" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

# variable "authorized_cidrs" {
#   type = list(string)
# }

# variable "authorized_entities" {
#   type = map(any)
# }

# variable "vault_version" {
#   type = string
# }

# variable "vault_hostname" {
#   type = string
# }

# variable "vm_admin_username" {
#   type = string
# }

# variable "vm_admin_public_key" {
#   type = string
# }

# variable "azure_dns_client_id" {
#   type = string
# }

# variable "azure_dns_client_secret" {
#   type = string
# }