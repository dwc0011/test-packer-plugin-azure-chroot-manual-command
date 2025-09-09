variable "resource_group" {
  description = "The name of the Azure Resource Group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "owner_tag" {
  description = "Owner tag for resources"
  type        = string
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true
}

variable "subnet_id" {
  description = "The ID of the subnet where the VM will be placed"
  type        = string
}

variable "packer_version" {
  description = "The version of Packer to use"
  default     = "1.14.1"
  type        = string
}

variable "owner_tag" {
  description = "Owner tag for the resources"
  default     = "dennis.carey@plus3it.com"
  type        = string
}

variable "packer_plugin_name" {
  description = "The name of the Packer plugin directory"
  default     = "packer-plugin-azure"
  type        = string
}


variable "packer_plugin_git_url" {
  description = "The Git URL for the Packer plugin repository"
  default     = "https://github.com/dwc0011/packer-plugin-azure.git"
  type        = string
}

variable "packer_plugin_git_branch" {
  description = "The Git branch for the Packer plugin repository"
  default     = "add-skip-mount-device-chroot-option"
  type        = string
}

variable "spel_git_url" {
  description = "The Git URL for the spel repository"
  default     = "https://github.com/plus3it/spel.git"
  type        = string
}

