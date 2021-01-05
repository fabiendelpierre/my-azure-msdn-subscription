variable "base_name" {
  type = string
}

variable "azure_region" {
  type = string
}

variable "sandbox_domain_name" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "authorized_cidrs" {
  type = list(string)
}

variable "authorized_entities" {
  type = map(any)
}