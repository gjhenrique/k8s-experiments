variable "domains" {
  type = map
}

variable "iso_url" {
  type = string
}

variable "ssh_private_key" {
  type = string
  default = null
}

variable "ssh_public_key" {
  type = string
  default = null
}

variable "template_file" {
  type = string
}

variable "cluster_name" {
  type = string
}
