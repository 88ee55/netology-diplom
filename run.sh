#!/usr/bin/env bash
set -x

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# check first arg
if [ -z "$1" ]
  then
    echo "Enter workspace as argument"
    exit 1
fi

# check and set workspace
workspace="$1"
shift
[[ "$workspace" != "prod" && "$workspace" != "stage" ]] && echo "workspace available prod or stage" && exit 1

# set default var
action="create"
profile="netology"
folder="netology"
k8s_name="netology"
sa_terraform="sa-terraform"
sa_github="sa-github"
app_ns="app"
app_release="app"

# set var from arg
while [[ $# -gt 0 ]]; do
  case "$1" in
    '--destroy'|'--delete') action="delete";;
    '--destroy-full'|'--delete-full') action="delete"; action_bucket="delete";;
    '--rekey') rekey="true";;
    '--profile') shift; profile="$1";;
    '--folder') shift; folder="$1";;
  esac
  shift
done

function yandex_init() {

    # first init
    while true
    do
        if ! yc config profile list | grep ^"$profile ACTIVE"$ &> /dev/null && ! yc resource-manager folder get "$folder" | grep "ERROR:" &> /dev/null
        then
            echo -e "create profile and folder. Enter name \e[41m$profile\e[0m (first run create default)"
            yc init
        else break
        fi
    done

    # check profile
    yc config profile activate "$profile"
    # set folder 4 terraform var
    yc config profile get "$profile" | grep folder | sed 's/: / = \"/' | sed 's/\(.*\)/\1"/g' | tee terraform.auto.tfvars

    # check sa_terraform and create
    sa "$sa_terraform"

    # get id sa
    sa_id=$(yc iam service-account get "$sa_terraform" | grep ^id | cut -c 5-)

    # set role 4 sa
    yc iam service-account set-access-bindings -y "$sa_terraform" \
        --access-binding role=admin,subject=serviceAccount:"${sa_id}" \
        &> /dev/null

    # set role folder 4 sa
    yc resource-manager folder set-access-bindings -y "$folder" \
        --access-binding role=admin,subject=serviceAccount:"${sa_id}" \
        &> /dev/null
}


function project_clear() {

    # key delete
    cd "$DIR"
    rm -f ${sa_terraform}.json ${sa_github}.yaml terraform.auto.tfvars

    # check sa and delete
    if yc iam service-account list | grep "$sa_terraform" &> /dev/null
    then
        yc iam service-account delete --name "$sa_terraform"
    fi

    #check folder and delete
    if yc resource-manager folder list | grep "$folder" &> /dev/null
    then
        echo "manual delete)" # yc resource-manager folder delete "$folder" --async
    fi

    #delete profile
    yc config profile create default
    yc config profile activate default
    # yc config profile delete "$profile" --async
}


function sa() {

    # check sa and create
    if ! yc iam service-account list | grep "$1" &> /dev/null
    then
        yc iam service-account create --name "$1"
    fi

    # delete old key in sa
    for line in $(yc iam key list --service-account-name "$1" --format yaml | grep "\- id" | cut -c 7-)
    do
        yc iam key delete --id "$line"
    done

    yc iam key create --service-account-name "$1" --output "$1.json" &> /dev/null
}


function terraform_project() {

    # terraform login
    [ ! -f ~/.terraform.d/credentials.tfrc.json ] && echo "create token terraform cloud" && terraform login

    # first init
    ec=$(terraform workspace list >/dev/null 2>&1)
    [ "$ec" == "0" ] || terraform init <<< "$workspace"

    terraform init

    # set active for delete other workspace
    workspace_exist=$(terraform workspace list | cut -c 3- | grep ^"$workspace"$) || true
    [ -z "$workspace_exist" ] && terraform workspace new temp 

    # check workspace
    workspace_exist=$(terraform workspace list | cut -c 3- | grep ^"$workspace"$) || true

    # create workspace
    [ -z "$workspace_exist" ] && terraform workspace new "$workspace"

    terraform workspace select "$workspace"

    # delete project
    [ "$action" == "delete" ] && terraform destroy -auto-approve

    # delete workspace
    [ "$action" == "delete" ] && terraform workspace select temp && terraform workspace delete "$workspace"

    # create project
    [ "$action" == "create" ] && terraform apply -auto-approve

    cd ..
}

function kube_config() {

    # get config
    yc managed-kubernetes cluster get-credentials "${k8s_name}-${workspace}" --external --force
}

function kube_monitoring() {

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
    # kubectl create ns ingress-nginx
    helm install -n ingress-nginx ingress-nginx ingress-nginx/ingress-nginx --create-namespace
    # kubectl create ns monitoring
    helm install -n monitoring \
        --set grafana.ingress.enabled=true \
        --set grafana.ingress.annotations."kubernetes\.io/ingress\.class"="nginx" \
        --set grafana.ingress.annotations."nginx\.ingress\.kubernetes\.io/rewrite-target"="/\$1" \
        --set grafana.ingress.annotations."nginx\.ingress\.kubernetes\.io/use-regex"=\"true\" \
        --set grafana.ingress.path="/grafana/?(.*)" \
        --set grafana."grafana\.ini".server.root_url="http://localhost:3000/grafana" \
        --create-namespace \
        monitoring prometheus-community/kube-prometheus-stack
}

function kube_app() {

    helm repo add netology https://88ee55.github.io/netology-helm/
    helm repo update
    helm install $app_release netology/myapp -n $app_ns --create-namespace --wait
}

function kube_config_github() {

    # sa 4 deploy
    kubectl create sa deploy -n app
    kubectl create clusterrolebinding deploy --clusterrole=edit --serviceaccount=$app_ns:deploy 

    context=$(kubectl config current-context)
    clusterName=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
    endpoint=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${clusterName}\")].cluster.server}")

    server=${endpoint}
    namespace="$app_ns"
    serviceAccount=deploy

    secretName=$(kubectl --namespace $namespace get serviceAccount $serviceAccount -o jsonpath='{.secrets[0].name}')
    ca=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.ca\.crt}')
    token=$(kubectl --namespace $namespace get secret/$secretName -o jsonpath='{.data.token}' | base64 --decode)

    echo "apiVersion: v1
kind: Config
clusters:
  - name: ${clusterName}
    cluster:
      certificate-authority-data: ${ca}
      server: ${server}
contexts:
  - name: ${serviceAccount}@${clusterName}
    context:
      cluster: ${clusterName}
      namespace: ${namespace}
      user: ${serviceAccount}
users:
  - name: ${serviceAccount}
    user:
      token: ${token}
current-context: ${serviceAccount}@${clusterName}" | base64 > ${sa_github}.yaml
}

# main
# yc create profile, service account
[ ! -f "terraform.auto.tfvars" ] || [ "$rekey" == "true" ] && yandex_init

# project create
[ "$action" == "create" ] && \
    terraform_project && \
    kube_config && \
    kube_monitoring && \
    kube_app && \
    kube_config_github

[ "$action" == "delete" ] && \
    terraform_project

# delete full
[ "$action_bucket" == "delete" ] && project_clear
