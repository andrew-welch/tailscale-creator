variable "resource_location" {
  default = "australiaeast"
}

variable "resource_group_name" {
  default = "az-tailscale"
}


variable "resource_2_location" {
  default = "southeastasia"
}

variable "resource_group_2_name" {
  default = "az-tailscale_sea"
}




variable "VM_PASSWORD" {
  type = string
  # Pulled from GitHub secrets
}

variable "TAILSCALE_AUTHKEY" {
  type = string
  # Pulled from GitHub secrets
}


variable "domain-name" {
  default = "example.com"
}