packer {
  required_plugins {
    azure = {
      version = ">= 2.4.0"
      source  = "github.com/hashicorp/azure"
    }
  }
}

locals {
  # Pull subscription ID from IMDS
  subscription_id = var.subscription_id
  # Pull resource group from IMDS
  resource_group  = var.resource_group

  location       = var.location

  image_sku = var.hyperv_generation == "V1" ? var.image_sku : "${var.image_sku}-gen2" 
}

###
# Variables specific to spel
###
variable "spel_identifier" {
  description = "Namespace that prefixes the name of the built images"
  type        = string
  default     = "chroot-sme"
}

variable "spel_root_volume_size" {
  description = "Size in GB of the root volume"
  type        = number
  default     = 20
}

variable "spel_version" {
  description = "Version appended to the name of the built images"
  type        = string
  default     = "devaz001"
}

variable "image_publisher" {
  type = string
  default = "SPEL-Custom"
}

variable "image_os_type" {
  type = string
  default = "Linux"
}

variable "image_offer" {
  type    = string
  default = "RHELcustom"
}

variable "image_sku" { 
  type = string 
  default = "9-lvm-gen1-chroot" 
}

variable "subscription_id" { 
  type = string  
}

variable "resource_group" {
  description = "The name of the Azure Resource Group"
  type        = string  
}
variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "hyperv_generation" {
  description = "The generation V1 or V2 of hyperv - based on OS and drive type ie V2 nvme"
  type = string
  default = "V1"
}

source "azure-chroot" "manual" {  
  use_azure_cli_auth = true
  from_scratch = true
  
  pre_mount_commands = [
    "echo 'Mandatory pre-mount command'",    
  ]
  manual_mount_command = "chmod +x /packerbuild/test-resources/scripts/mount.sh && export SOURCE_NAME_ENV='${source.name}' && export SPEL_AMIGENBUILDDEV='{{ .Device }}' && bash -x /packerbuild/test-resources/scripts/mount.sh" 
  os_disk_size_gb     = var.spel_root_volume_size

  image_resource_id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.resource_group}/providers/Microsoft.Compute/images/${var.image_publisher}-${local.image_sku}-{{timestamp}}"

  image_hyperv_generation = var.hyperv_generation
}

build {
 
  sources = ["source.azure-chroot.manual"]
}
