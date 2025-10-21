## Prerequisites 

- git
- terraform
- azure login credentials 
  - configured to allow terraform to inherit

## Important Project files

- `azure-chroot.pki.hcl` - defines the packer build, ensure you review the `manual_mount_command`
  - **note:** minimal config update as required
- `scripts/mount.sh` - called by ‘azure-chroot.pkr.hcl’ via the manual_mount_command option
  -  Sets up required env vars that are used by `builder-prep-9.sh` and `amigen9-build-sh` scripts and executest them
- `main.tf` - deploys azure instance and resources used as the chroot instance, it is also the build instance to build custom azure packer plugin
  - **note:** userdata clones the required repos and creates helper scripts useful for building the custom packer plugin, validating hcl file, and running packer

## Usage

	1.	git clone https://github.com/dwc0011/test-packer-plugin-azure-chroot-manual-command.git
	2.	cd to folder
	3.	create terraform.tfvars (See variables below)
	4.	login to azure cli / configure so terraform can inherit access
	5.	run terraform init/plan/apply -note the outputs for public ip and resource group name which appends randomness to the name.
	6.	ssh to the azure instance - login with admin password if prompted
	7.	sudo su - root
	8.	cd /packerbuild
	9.	run helper scripts (created by userdata) to build packer plugin azure, validate the packer file, and run packer.
	⁃	/packerbuild/builder_packer.sh
	⁃	/packerbuild/validate_packer.sh
	⁃	/packerbuild/run_packer.sh
	10.  View logs - /packerbuild/packer.log
	11.  Once completed - go test the build image. (which inherits the resource group name)

## terraform.tfvars template

```
my_ip             = “IP YOU WILL USE TO CONNECT TO THE AZURE INSTANCE”
ssh_pub_key_path  = “SSH KEY TO USE FOR SSH TO AZURE INSTANCE”
owner_tag         = “EMAIL ADDRESS FOR TAG TO ADD TO AZURE INSTANCE”
vm_size           = “Size of VM - default is Standard_D2s_v4"
image_sku		      = “IMAGE SKU defaults is 9-raw”
admin_password    = “PASSWORD FOR INSTANCE”
azure_subscription_id = “AZURE SUBSCRIPTION ID”
packer_version        = “Defaults to 1.14.2”
```

## Additional Info
Link for the `packer-plugin-azure` repo and branch that is used by the instance:

https://github.com/dwc0011/packer-plugin-azure/tree/add-manual-mount-command-option

### Unused Files
- scripts/resize.sh - used for NVME drive testing
- mise.toml - Used to install packer locally - not needed
