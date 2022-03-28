variable "name" {
  type = string
}

variable "k8s_release" {
  type    = string
  default = "STABLE"

  validation {
    condition     = contains(["STABLE", "REGULAR", "RAPID"], var.k8s_release)
    error_message = "Release only STABLE or REGULAR or STABLE."
  }
}

variable "k8s_version" {
  default = "1.21"
  type    = string
}

variable "network" {
}

variable "subnet_service" {
}

variable "sa_service" {
}

variable "sa_node" {
}

variable "kms" {
}