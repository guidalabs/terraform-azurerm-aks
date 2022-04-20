# Velero storageaccount settings
variable "velero" {
  type = map(any)
  default = {
    enabled = false
  }
}

variable "location" {
  description = "The Azure Region where the resources should exist. Changing this forces a new resources to be created"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "Any tags that should be present on the Virtual Network resources"
  default     = {}
}
