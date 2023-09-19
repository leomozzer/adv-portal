variable "app_name" {
  type = string
}

variable "location" {
  type = string
}

variable "location_short" {
  type = string
}

variable "environment" {
  type = string
}

variable "network_vnet_cidr" {
  type        = list(string)
  description = "The CIDR of the network VNET"
  default = [
    "10.128.0.0/24"
  ]
}

variable "network_subnet_cidr" {
  type        = list(string)
  description = "The CIDR for the network subnet"
  default = [
    "10.128.0.0/24"
  ]
}

variable "queue_list" {
  type    = list(string)
  default = []
}

variable "table_list" {
  type    = list(string)
  default = []
}

