output "key" {
  value = yandex_iam_service_account_static_access_key.this
}

output "id" {
  value = yandex_iam_service_account.this.id
}