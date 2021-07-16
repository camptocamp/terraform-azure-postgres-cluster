variable "subnet_id" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "instance_count" {
  type = number
  default = 2
}

variable "name" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "dns_zone_name" {
  type = string
}
