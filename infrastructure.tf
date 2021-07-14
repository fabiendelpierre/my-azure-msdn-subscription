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
  resource_group_name = azurerm_resource_group.msdn_sandbox.name
  ttl                 = 3600

  records = [
    "ns-1746.awsdns-26.co.uk",
    "ns-920.awsdns-51.net",
    "ns-449.awsdns-56.com",
    "ns-1440.awsdns-52.org.",
  ]

  tags = local.tags
}