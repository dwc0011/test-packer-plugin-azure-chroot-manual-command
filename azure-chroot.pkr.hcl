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
  subscription_id = trimspace(chomp(shell("curl -s -H Metadata:true \"http://169.254.169.254/metadata/instance?api-version=2021-02-01\" | jq -r .compute.subscriptionId")))

  # Pull resource group from IMDS
  resource_group  = trimspace(chomp(shell("curl -s -H Metadata:true \"http://169.254.169.254/metadata/instance?api-version=2021-02-01\" | jq -r .compute.resourceGroupName")))

   location       = trimspace(chomp(shell("curl -s -H Metadata:true \"http://169.254.169.254/metadata/instance?api-version=2021-02-01\" | jq -r .compute.location")))
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

variable "gallery_name" {
  type    = string
  default = "devaz001_rhel9_gallery"
}

variable "image_definition_name" {
  type    = string
  default = "rhel9-lvm-chroot-builder-from-scratch"
}

variable "image_version"   { type = string default = "1.0.0" }

source "azure-chroot" "manual" {  
  from_scratch = true
  subscription_id     = local.subscription_id
  resource_group_name = local.resource_group
  location            = local.location
  pre_mount_commands = [
    "echo 'Mandatory pre-mount command'",    
  ]
  manual_mount_command = "chmod +x /packerbuild/test-resources/scripts/mount.sh && export SOURCE_NAME_ENV='${source.name}' && export SPEL_AMIGENBUILDDEV='{{ .Device }}'' && bash -x /packerbuild/test-resources/scripts/mount.sh" 
  os_disk_size_gb     = var.spel_root_volume_size

   shared_image_destination {
    subscription   = local.subscription_id
    resource_group = local.resource_group
    gallery_name   = var.gallery_name
    image_name     = var.image_definition_name
    image_version  = var.image_version
  }

  
}

build {
  sources = ["source.azure-chroot.manual"]
}
