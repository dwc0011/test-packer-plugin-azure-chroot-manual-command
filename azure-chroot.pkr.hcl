packer {
  required_plugins {
    azure = {
      version = ">= 2.4.0"
      source  = "github.com/hashicorp/azure"
    }
  }
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
  default     = "devdc001"
}

source "azure-chroot" "manual" {  
  from_scratch = true
  pre_mount_commands = [
    "echo 'Mandatory pre-mount command'",    
  ]
  manual_mount_command = "chmod +x ./scripts/mount.sh && export SOURCE_NAME_ENV=${source.name} && bash -x ./scripts/mount.sh" 
  os_disk_size_gb     = var.spel_root_volume_size


  image_resource_id   = "/subscriptions/{{vm `subscription_id`}}/resourceGroups/{{vm `resource_group`}}/providers/Microsoft.Compute/images/rhel9‑chroot‑image‑${var.spel_identifier}-${var.spel_version}"

}

build {
  sources = ["source.azure-chroot.manual"]
}
