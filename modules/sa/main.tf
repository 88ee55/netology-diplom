resource "yandex_iam_service_account" "this" {
  folder_id = var.folder
  name      = var.name
}

resource "yandex_resourcemanager_folder_iam_member" "this" {
  folder_id = var.folder
  role      = var.role
  member    = "serviceAccount:${yandex_iam_service_account.this.id}"
}

resource "yandex_iam_service_account_static_access_key" "this" {
  service_account_id = yandex_iam_service_account.this.id
  description        = "static access key"
}