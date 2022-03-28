variable "name" {
  type = string
}

variable "cluster_id" {
}

variable "k8s_version" {
  default = "1.21"
  type    = string
}

variable "subnet_node" {
}

variable "k8s_node" {
  default = {
    resources = {
      memory        = 2
      cores         = 2
      core_fraction = 20
    }
    boot_disk = {
      type = "network-hdd"
      size = 30
    }
    scale_policy = {
      fixed_scale = {
        size = 3
      }
    }
  }
}