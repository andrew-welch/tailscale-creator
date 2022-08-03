packer {
  required_plugins {
    azure-arm = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "AZ_CLIENT_ID" {
  default = env("AZURE_CLIENT_ID")
}

variable "AZ_CLIENT_SECRET" {
  default = env("AZURE_CLIENT_SECRET")
}

variable "AZ_SUBSCRIPTION_ID" {
  default = env("AZURE_SUBSCRIPTION_ID")
}


source "azure-arm" "image-create" {
    client_id           = var.AZ_CLIENT_ID
    client_secret       = var.AZ_CLIENT_SECRET
    subscription_id     = var.AZ_SUBSCRIPTION_ID

    managed_image_name = "az-wireguard-image-noconfig"
    managed_image_resource_group_name = "az-tailscale-packer-images"

    os_type         = "Linux"
    image_publisher = "debian"
    image_offer     = "debian-10"
    image_sku       = "10"

    azure_tags = {
        managed = "packer"
    }

    location = "australiaeast"
    vm_size  = "Standard_B1s"
}

build {
  name    = "tailscale-wireguard"
  sources = ["sources.azure-arm.image-create"]

  provisioner "shell" {
    # Azure generalising script
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline = [
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang = "/bin/sh -x"
  }

}