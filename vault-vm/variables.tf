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

variable "my_ip_addresses" {
  type = list(string)
}