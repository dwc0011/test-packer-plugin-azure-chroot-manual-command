data "azurerm_subscription" "current" {
}

resource "random_pet" "this" {
  prefix = var.resource_group
}

resource "random_string" "suffix" {
  length    = 2
  special   = false
  min_lower = 2
}

resource "azurerm_resource_group" "this" {
  name     = random_pet.this.id
  location = var.location
}

resource "azurerm_storage_account" "this" {
  name                     = "rhel9packerstorage${random_string.suffix.id}"
  resource_group_name      = local.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Owner = var.owner_tag
  }
}

locals{
  resource_group = azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "packer-builder-identity${random_string.suffix.id}"
  resource_group_name = local.resource_group
  location            = var.location

  tags = {
    Owner = var.owner_tag
  }
}

resource "azurerm_virtual_network" "this" {
  name                = "rhel9-builder-vent-${random_string.suffix.id}"
  address_space       = [var.vnet_cider]
  location            = azurerm_resource_group.this.location
  resource_group_name = local.resource_group
}

resource "azurerm_subnet" "this" {
  name                 = "rhel9-builder-subnet-${random_string.suffix.id}"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.subnet_cidr_prefix]
}

# Create a public IP address
resource "azurerm_public_ip" "this" {
  name                = "rhel-builder-pip-ssh-${random_string.suffix.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = local.resource_group
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "this" {
  name                = "rhel9-builder-nsg-${random_string.suffix.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = local.resource_group
}

resource "azurerm_network_security_rule" "ob" {
  name                        = "rhel9-builder-sg-rule-ob-${random_string.suffix.id}"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  network_security_group_name = azurerm_network_security_group.this.name
  resource_group_name         = local.resource_group
}

resource "azurerm_network_security_rule" "ssh" {
  name                        = "rhel9-builder-sg-rule-ssh-${random_string.suffix.id}"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_ip
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.this.name
  resource_group_name         = local.resource_group
}

resource "azurerm_network_interface" "this" {
  name                = "rhel9-builder-nic-${random_string.suffix.id}"
  location            = var.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "rhel9-with-packer-chroot-builder-${random_string.suffix.id}"
  location            = var.location
  resource_group_name = local.resource_group
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_pub_key_path)
  }

  identity {
    type         = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y dnf-utils wget unzip curl gnupg jq git go-toolset lvm2
    dnf install cloud-utils-growpart gdisk

    mkdir -p /packerbuild/test-resources
  

    echo "#!/bin/bash" > /packerbuild/build_packer.sh
    echo "cd /packerbuild/${var.packer_plugin_name}" >> /packerbuild/build_packer.sh
    echo "make dev" >> /packerbuild/build_packer.sh
    chmod +x /packerbuild/build_packer.sh

    echo "#!/bin/bash" > /packerbuild/run_packer.sh
    echo "cd /packerbuild" > /packerbuild/run_packer.sh
    echo "/usr/local/bin/packer init azure-chroot.pkr.hcl" >> /packerbuild/run_packer.sh
    echo "export PACKER_LOG=1" >> /packerbuild/run_packer.sh
    echo "export PACKER_LOG_PATH=/packerbuild/packer.log" >> /packerbuild/run_packer.sh
    echo "/usr/local/bin/packer build --var subscription_id=${data.azurerm_subscription.current.subscription_id} --var resource_group=${local.resource_group} --var location=${var.location} azure-chroot.pkr.hcl &" >> /packerbuild/run_packer.sh
    chmod +x /packerbuild/run_packer.sh

    echo "#!/bin/bash" > /packerbuild/validate_packer.sh
    echo "export PACKER_LOG=1" >> /packerbuild/validate_packer.sh
    echo "export PACKER_LOG_PATH=/packerbuild/packer.log" >> /packerbuild/validate_packer.sh
    echo "cd /packerbuild" > /packerbuild/validate_packer.sh
    echo "/usr/local/bin/packer init azure-chroot.pkr.hcl" >> /packerbuild/validate_packer.sh
    echo "/usr/local/bin/packer validate --var subscription_id=${data.azurerm_subscription.current.subscription_id} --var resource_group=${local.resource_group} --var location=${var.location} azure-chroot.pkr.hcl &" >> /packerbuild/validate_packer.sh
    chmod +x /packerbuild/validate_packer.sh

    git clone ${var.test_packer_plugin_git_url} /packerbuild/test-resources
    cp /packerbuild/test-resources/azure-chroot.pkr.hcl /packerbuild/azure-chroot.pkr.hcl    
    chmod +x /packerbuild/test-resources/scripts/*.sh  

   
    git clone ${var.packer_plugin_git_url} /packerbuild/${var.packer_plugin_name}
    cd /packerbuild/${var.packer_plugin_name}
    git checkout ${var.packer_plugin_git_branch}

    # Get the spel scripts and put in the proper location for packer 
    git clone ${var.spel_git_url} /packerbuild/spel
    chmod +x /packerbuild/spel/spel/scripts/*.sh


    PACKER_VERSION="${var.packer_version}"
    curl -Lo packer.zip https://releases.hashicorp.com/packer/$${PACKER_VERSION}/packer_$${PACKER_VERSION}_linux_amd64.zip
    unzip packer.zip
    mv packer /usr/local/bin/
    chmod +x /usr/local/bin/packer
    
    /packerbuild/test-resources/scripts/resize.sh

  EOF
  )

  tags = {
    Name  = "rhel9-with-packer-chroot-builder-${random_string.suffix.id}"
    Owner = var.owner_tag
  }
}

