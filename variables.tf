variable "my_ip" {
  description = "Your public IP address"
  type        = string
}

variable "ssh_pub_key_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "resource_group" {
  description = "The name of the Azure Resource Group"
  type        = string
  default     = "packer-plugin-test-rg"
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
  default     = "Standard_D2s_v4"
}

variable "image_sku" {
  description = "SKU for the image"
  type        = string
  default     = "9-raw"
}

variable "hyperv_generation" {
  description = "The hyperv generation version V1 or V2 must match OS gen"
  type        = string
  default     = "V1"
}

variable "admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "packeruser"
}

variable "admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  sensitive   = true
}

variable "vnet_cider" {
  description = "The CIDR block for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_prefix" {
  description = "The CIDR prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "packer_version" {
  description = "The version of Packer to use"
  default     = "1.14.1"
  type        = string
}

variable "packer_plugin_name" {
  description = "The name of the Packer plugin directory"
  default     = "packer-plugin-azure"
  type        = string
}

variable "test_packer_plugin_git_url" {
  description = "The Git URL for the test resources to test Packer plugin repository"
  default     = "https://github.com/dwc0011/test-packer-plugin-azure-chroot-manual-command.git"
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

variable "spel_git_branch" {
  description = "The Git branch for the SPEL Repo"
  default     = "master"
  type        = string
}

variable "packer_on_error" {
  description = "What to do when packer encounters an error (cleanup (default), abort, ask, run-cleanup-provisioner)"
  default     = "cleanup"
  type        = string
}
