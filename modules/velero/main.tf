# Required for velero backup with storageaccount See https://github.com/vmware-tanzu/velero-plugin-for-microsoft-azure/blob/main/README.md

resource "azurerm_storage_account" "velero" {
  count                             = var.velero.enabled ? 1 : 0
  access_tier                       = try(var.velero.access_tier, "Hot")
  account_kind                      = try(var.velero.account_kind, "StorageV2")
  account_replication_type          = try(var.velero.account_replication_type, "LRS")
  account_tier                      = try(var.velero.account_tier, "Standard")
  allow_blob_public_access          = try(var.velero.allow_blob_public_access, false)
  enable_https_traffic_only         = try(var.velero.enable_https_traffic_only, true)
  infrastructure_encryption_enabled = try(var.velero.infrastructure_encryption_enabled, false)
  is_hns_enabled                    = try(var.velero.is_hns_enabled, false)
  location                          = try(var.velero.location, null)
  min_tls_version                   = try(var.velero.min_tls_version, "TLS1_2")
  name                              = try(var.velero.name, null)
  nfsv3_enabled                     = try(var.velero.nfsv3_enabled, false)
  queue_encryption_key_type         = try(var.velero.queue_encryption_key_type, "Service")
  resource_group_name               = try(var.velero.resource_group_name, null)
  shared_access_key_enabled         = try(var.velero.shared_access_key_enabled, true)
  table_encryption_key_type         = try(var.velero.table_encryption_key_type, "Service")

  tags = try(var.velero.tags, {})

  blob_properties {
    change_feed_enabled      = true
    last_access_time_enabled = false
    versioning_enabled       = false
    delete_retention_policy {
      days = try(var.velero.delete_retention_policy, 7)
    }
  }

  network_rules {
    bypass = [
      "AzureServices",
    ]
    default_action = "Deny"
    ip_rules       = try(var.velero.ip_rules, [])

    # Need to check if we want this
    # dynamic "private_link_access" {
    #   for_each = (var.managed_identity ? [1] : [])
    #   content {
    #     endpoint_resource_id = azurerm_user_assigned_identity.velero[0].id
    #     endpoint_tenant_id   = azurerm_user_assigned_identity.velero[0].tenant_id
    #   }
    # }

  }
}

resource "azurerm_storage_container" "velero" {
  count                 = var.velero.enabled ? 1 : 0
  name                  = try(var.velero.storage_container_name, null)
  storage_account_name  = azurerm_storage_account.velero.0.name
  container_access_type = try(var.velero.container_access_type, "private")
}

resource "azurerm_private_endpoint" "velero" {
  count               = var.velero.enabled ? 1 : 0
  name                = try(var.velero.private_endpoint_name, null)
  location            = try(var.velero.location, null)
  resource_group_name = try(var.velero.resource_group_name, null)
  subnet_id           = try(var.velero.private_endpoint_subnet_id, null)

  private_service_connection {
    name                           = "privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.velero.0.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  private_dns_zone_group {
    name                 = "blob"
    private_dns_zone_ids = try(var.velero.private_dns_zone_ids, null)
  }
}

# Velero storageaccount settings
variable "velero" {
  type = map(any)
  default = {
    enabled = false
  }
}
