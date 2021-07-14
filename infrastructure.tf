resource "azurerm_resource_group" "infra" {
  name     = "${var.base_name}-infra"
  location = var.azure_region

  tags = local.tags
}

resource "azurerm_dns_zone" "msdn_sandbox" {
  name                = var.sandbox_domain_name
  resource_group_name = azurerm_resource_group.infra.name

  tags = local.tags
}

# Delegation to my sandbox DNS zone in AWS Route 53
resource "azurerm_dns_ns_record" "aws_sandbox" {
  name                = "aws"
  zone_name           = azurerm_dns_zone.msdn_sandbox.name
  resource_group_name = azurerm_resource_group.infra.name
  ttl                 = 3600

  records = [
    "ns-1746.awsdns-26.co.uk",
    "ns-920.awsdns-51.net",
    "ns-449.awsdns-56.com",
    "ns-1440.awsdns-52.org.",
  ]

  tags = local.tags
}

resource "azurerm_virtual_network" "msdn_sandbox" {
  name                = "${var.base_name}-vnet"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.infra.name
  address_space       = var.vnet_address_space

  tags = local.tags
}

resource "azurerm_subnet" "msdn_sandbox1" {
  name                 = "${azurerm_virtual_network.msdn_sandbox.name}-subnet1"
  resource_group_name  = azurerm_resource_group.infra.name
  virtual_network_name = azurerm_virtual_network.msdn_sandbox.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space[0], 4, 0)]

  service_endpoints = [
    "Microsoft.AzureActiveDirectory",
    "Microsoft.ContainerRegistry",
    "Microsoft.KeyVault",
    "Microsoft.Storage",
  ]
}

resource "azurerm_network_security_group" "msdn_sandbox1" {
  name                = "${azurerm_subnet.msdn_sandbox1.name}-nsg"
  resource_group_name = azurerm_resource_group.infra.name
  location            = var.azure_region

  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "msdn_sandbox1" {
  subnet_id                 = azurerm_subnet.msdn_sandbox1.id
  network_security_group_id = azurerm_network_security_group.msdn_sandbox1.id
}
