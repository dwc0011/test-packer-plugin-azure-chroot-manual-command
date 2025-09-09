resource "azurerm_storage_account" "this" {
  name                     = "rhel9packerstorage"
  resource_group_name      = var.resource_group
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    Name  = "rhel9-with-packer-chroot-builder"
    Owner = var.owner_tag
  }
}

resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_id  = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_storage_blob" "packer_template" {
  name                   = "azure-chroot.pkr.hcl"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/azure-chroot.pkr.hcl"
}

resource "azurerm_storage_blob" "mount" {
  name                   = "scripts/mount.sh"
  storage_account_name   = azurerm_storage_account.this.name
  storage_container_name = azurerm_storage_container.scripts.name
  type                   = "Block"
  source                 = "${path.module}/scripts/mount.sh"
}

resource "azurerm_user_assigned_identity" "this" {
  name                = "packer-builder-identity"
  resource_group_name = var.resource_group
  location            = var.location

  tags = {
    Name  = "packer-builder"
    Owner = var.owner_tag
  }
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "rhel9-builder-nsg"
  location            = var.location
  resource_group_name = var.resource_group

  security_rule {
    name                       = "AllowInternetOut"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = {
    Name  = "rhel9-builder-nsg"
    Owner = var.owner_tag
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = "rhel9-builder"
  location            = var.location
  resource_group_name = var.resource_group
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]
  size               = var.vm_size
  admin_username     = var.admin_username
  admin_password     = var.admin_password
  disable_password_authentication = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9_1"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y dnf-utils wget unzip curl jq git python3 python3-pip go-toolset lvm2

    mkdir -p /packerbuild

    echo "#!/bin/bash" > /packerbuild/build_packer.sh
    echo "cd /packerbuild/${var.packer_plugin_name}" >> /packerbuild/build_packer.sh
    echo "make dev" >> /packerbuild/build_packer.sh
    chmod +x /packerbuild/build_packer.sh

    echo "#!/bin/bash" > /packerbuild/run_packer.sh
    echo "cd /packerbuild" > /packerbuild/run_packer.sh
    echo "packer init azure-chroot.pkr.hcl" >> /packerbuild/run_packer.sh
    echo "export PACKER_LOG=1" >> /packerbuild/run_packer.sh
    echo "export PACKER_LOG_PATH=/packerbuild/packer.log" >> /packerbuild/run_packer.sh
    echo "packer build azure-chroot.pkr.hcl &" >> /packerbuild/run_packer.sh
    chmod +x /packerbuild/run_packer.sh

    pip3 install azure-cli

    az login --identity
    az storage blob download-batch -d /packerbuild/ -s scripts --account-name ${azurerm_storage_account.this.name}

   
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
  EOF
  )

  tags = {
    Name  = "rhel9-with-packer-chroot-builder"
    Owner = var.owner_tag
  }
}

resource "azurerm_network_interface" "this" {
  name                = "rhel9-builder-nic"
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}
