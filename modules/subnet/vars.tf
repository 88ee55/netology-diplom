variable "name" {
  type = string
}

variable "cidr" {
}

variable "network" {
}

variable "zone" {
  default = "ru-central1-c"
  type    = string
}

variable "route_table" {
  default = ""
}

variable "prefix" {
  default = "default"
  type    = string
}