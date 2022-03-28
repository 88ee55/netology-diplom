resource "yandex_kms_symmetric_key" "this" {
  name              = var.name
  default_algorithm = "AES_128"
}