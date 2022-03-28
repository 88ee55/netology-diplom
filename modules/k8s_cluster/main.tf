resource "yandex_kubernetes_cluster" "regional" {
  name = var.name

  network_id = var.network

  master {
    regional {
      region = "ru-central1"

      dynamic "location" {
        for_each = var.subnet_service
        content {
          zone      = location.key
          subnet_id = location.value.subnet_id
        }
      }
    }

    version   = var.k8s_version
    public_ip = true
  }

  service_account_id      = var.sa_service
  node_service_account_id = var.sa_node

  release_channel = var.k8s_release

  kms_provider {
    key_id = var.kms.key.id
  }
}