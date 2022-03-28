resource "yandex_kubernetes_node_group" "this" {
  cluster_id = var.cluster_id
  name       = var.name
  version    = var.k8s_version

  instance_template {
    platform_id = lookup(var.k8s_node, "platform_id", "standard-v3")

    network_interface {
      subnet_ids = lookup(var.k8s_node.scale_policy, "fixed_scale", null) == null ? [for k, v in var.subnet_node : v.subnet_id if k == var.k8s_node.location] : [for k, v in var.subnet_node : v.subnet_id]
    }

    resources {
      memory        = var.k8s_node.resources.memory
      cores         = var.k8s_node.resources.cores
      core_fraction = var.k8s_node.resources.core_fraction
    }

    scheduling_policy {
      preemptible = lookup(var.k8s_node, "preemptible", false)
    }

    boot_disk {
      type = var.k8s_node.boot_disk.type
      size = var.k8s_node.boot_disk.size
    }

    container_runtime {
      type = "containerd"
    }
  }

  scale_policy {
    dynamic "fixed_scale" {
      for_each = lookup(var.k8s_node.scale_policy, "fixed_scale", null) == null ? {} : var.k8s_node.scale_policy
      content {
        size = fixed_scale.value.size
      }
    }

    dynamic "auto_scale" {
      for_each = lookup(var.k8s_node.scale_policy, "auto_scale", null) == null ? {} : var.k8s_node.scale_policy
      content {
        initial = auto_scale.value.initial
        min     = auto_scale.value.min
        max     = auto_scale.value.max
      }
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = lookup(var.k8s_node.scale_policy, "fixed_scale", null) == null ? [for k, v in var.subnet_node : k if k == var.k8s_node.location] : [for k, v in var.subnet_node : k]
      content {
        zone = location.value
      }
    }
  }
}