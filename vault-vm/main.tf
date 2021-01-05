### NETWORKING BITS
resource "azurerm_application_security_group" "vault" {
  name = "${var.base_name}-vault-appsg"

  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location

  tags = var.tags
}

## IP/interface stuff
resource "azurerm_public_ip" "vault" {
  name                = "${var.base_name}-vault-publicip01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_network_interface" "vault" {
  name                = "${var.base_name}-vault-nic01"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = var.location

  ip_configuration {
    name                          = "${var.base_name}-vault-nic01"
    subnet_id                     = data.azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vault.id
  }

  tags = var.tags
}

resource "azurerm_network_interface_application_security_group_association" "vault" {
  network_interface_id          = azurerm_network_interface.vault.id
  application_security_group_id = azurerm_application_security_group.vault.id
}

## Inbound firewall
resource "azurerm_network_security_rule" "inbound_ssh" {
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = data.azurerm_network_security_group.main.name

  name = "inbound-ssh"

  priority                                   = 1000
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefixes                    = var.my_ip_addresses
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.vault.id]
  destination_port_range                     = "22"
}

resource "azurerm_network_security_rule" "inbound_https" {
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = data.azurerm_network_security_group.main.name

  name = "inbound-https"

  priority                                   = 1100
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefixes                    = var.my_ip_addresses
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.vault.id]
  destination_port_range                     = "443"
}

## Outbound firewall
resource "azurerm_network_security_rule" "outbound_azure_key_vault" {
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = data.azurerm_network_security_group.main.name

  name = "outbound-azure-key-vault"

  priority                              = 1000
  direction                             = "Outbound"
  access                                = "Allow"
  protocol                              = "Tcp"
  source_application_security_group_ids = [azurerm_application_security_group.vault.id]
  source_port_range                     = "*"
  destination_address_prefix            = "AzureKeyVault"
  destination_port_range                = "*"
}

resource "azurerm_network_security_rule" "outbound_http_to_internet" {
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = data.azurerm_network_security_group.main.name

  name = "outbound-http-to-internet"

  priority                              = 1500
  direction                             = "Outbound"
  access                                = "Allow"
  protocol                              = "Tcp"
  source_application_security_group_ids = [azurerm_application_security_group.vault.id]
  source_port_range                     = "*"
  destination_address_prefix            = "Internet"
  destination_port_ranges               = ["80", "443"]
}

### DNS BITS
resource "azurerm_dns_a_record" "vault" {
  name                = "vault"
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.vault.ip_address]
}

### ROLE/IAM STUFF FOR THE VAULT VM
resource "azurerm_user_assigned_identity" "vault" {
  resource_group_name = azurerm_resource_group.sandbox.name
  location            = azurerm_resource_group.sandbox.location

  name = "${var.base_name}-vault-vm-identity"

  tags = var.tags
}
