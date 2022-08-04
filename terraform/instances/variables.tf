variable "resource_location" {
  default = "australiaeast"
}

variable "resource_group_name" {
  default = "az-tailscale"
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