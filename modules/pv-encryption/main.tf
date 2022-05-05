# By default, data is encrypted with Microsoft-managed keys. Below you will find the requirements to supply customer-managed keys for AKS disk encryption.
# Reference: https://docs.microsoft.com/en-us/azure/aks/azure-disk-customer-managed-keys

resource "azurerm_key_vault" "kv" {
  count                       = var.pv_encryption.enabled ? 1 : 0
  name                        = try(var.pv_encryption.kv_name, null)
  location                    = try(var.pv_encryption.location, null)
  resource_group_name         = try(var.pv_encryption.resource_group_name, null)
  enabled_for_disk_encryption = true # Required for Disk Encryption Set keys
  tenant_id                   = try(var.pv_encryption.tenant_id, null)
  soft_delete_retention_days  = try(var.pv_encryption.soft_delete_retention_days, 7)
  purge_protection_enabled    = true # Disk Encryption Set requires Key vault with purge protection
  sku_name                    = try(var.pv_encryption.sku_name, "standard")

  access_policy {
    tenant_id = try(var.pv_encryption.sp_tenant_id, null)
    object_id = try(var.pv_encryption.sp_object_id, null)

    key_permissions = [
      "Get",
      "Create",
      "Delete"
    ]
    secret_permissions  = []
    storage_permissions = []
  }
  network_rules {
    bypass = [
      "AzureServices",
    ]
    default_action = "Deny"
    ip_rules       = try(var.pv_encryption.ip_rules, [])
  }
}

resource "azurerm_key_vault_access_policy" "des" {
  count        = var.pv_encryption.enabled ? 1 : 0
  key_vault_id = azurerm_key_vault.kv[0].id
  tenant_id    = azurerm_disk_encryption_set.des.identity.0.tenant_id
  object_id    = azurerm_disk_encryption_set.des.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_key_vault_key" "kvk" {
  count        = var.pv_encryption.enabled ? 1 : 0
  name         = try(var.pv_encryption.kvk_name, format("%s-%s", "kvk", var.pv_encryption.suffix))
  key_vault_id = azurerm_key_vault.kv[0].id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "des" {
  count               = var.pv_encryption.enabled ? 1 : 0
  name                = try(var.pv_encryption.des_name, format("%s-%s", "des", var.pv_encryption.suffix))
  resource_group_name = try(var.pv_encryption.resource_group_name, null)
  location            = var.location
  key_vault_key_id    = azurerm_key_vault_key.kvk[0].id

  identity {
    type = "SystemAssigned"
  }
}

output "des_resource_id" {
  value = azurerm_disk_encryption_set.des[0].id
}

# Persistent volume encryption settings
variable "pv_encryption" {}