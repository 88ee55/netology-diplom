terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.70.0"
    }
  }

  cloud {
    organization = "88ee55"

    workspaces {
      tags = ["netology"]
    }
  }
}
