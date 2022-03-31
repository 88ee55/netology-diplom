1. Репозиторий с конфигурационными файлами Terraform и готовность продемонстрировать создание всех ресурсов с нуля.
[terraform](https://github.com/88ee55/netology-diplom)
В дипломе используется:
* Managed Service for Kubernetes
* Terraform CLoud
* Github:
  + vcs
  + ci/cd pipeline Actions
  + container registry
  + pages для репозитория helm

Подготовка инфрастуктуры находится в файле run.sh
Параметры запуска:
```
  workspace - имя окружения (может быть stage или prod)
  --delete - удалить кластер из окружения
  --delete-full - удалить кластер, окружение, профиль
```
При первом запуске ```./run.sh stage``` будет предложено настроить профиль yc (указать название профиля и токен).
В процессе будет создан файл _sa-terraform.json_ с учетными данными для terraform.

Основной этап.
* Развёртывание кластера в yandex cloud через terraform.
* Импорт конфигурации для kubectl.
* Развёртывание мониторинга через helm
* Развёртывание приложения через helm 
* Экспорт учетных данных для github actions (нужно будет создать секрет KUBE_CONFIG_DATA)


2. Пример pull request с комментариями созданными atlantis'ом или снимки экрана из Terraform Cloud.
![Terraform Cloud](terraform.png)
3. ~~Репозиторий с конфигурацией ansible, если был выбран способ создания Kubernetes кластера при помощи ansible.~~
4. Репозиторий с Dockerfile тестового приложения и ссылка на собранный docker image.
[app](https://github.com/88ee55/netology-app)
5. Репозиторий с конфигурацией Kubernetes кластера.
[helm](https://github.com/88ee55/netology-helm)
6. Ссылка на тестовое приложение и веб интерфейс Grafana с данными доступа.
[app](http://51.250.98.28)
[grafana](http://51.250.98.28/grafana/) admin/netology
7. Все репозитории рекомендуется хранить на одном ресурсе (github, gitlab)
[github](https://github.com/88ee55)
