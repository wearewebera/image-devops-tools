#!/usr/bin/env bash
[ "${BASH_VERSINFO:-0}" -ge 4 ] || { echo "Upgrade your bash to at least version 4"; exit 1; }

# Script create to be self-contained and install several basic utilities. Works on Ubuntu and its docker images
set -e
umask 022
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/sbin:

# Some emojis
OK='echo -e \xE2\x9C\x94'
NOK='echo -e \xE2\x9C\x96'
BEER='\xF0\x9F\x8D\xBA'
TEACUP='\xF0\x9F\x8D\xB5'
GREEN="\e[32m"
RED="\e[31m"
NORMAL="\e[0m"


# Configuration definitions
BIN_DIR=${HOME}/bin
TMP_DIR=${HOME}/tmp/workstation-tmp
LOG_FILE="/dev/null"
UBUNTU_PACKAGES=(
  apt-utils
  docker.io
  vim
  build-essential
  git
  golang
  curl
  wget
  python3
  python3-dev
  python3-pip
  software-properties-common
  unzip
  jq
)

mkdir -p ${BIN_DIR} ${TMP_DIR}
cd ${TMP_DIR}

function echoRed() {
  echo -e "${RED}${1}${NORMAL}"
}

function echoGreen() {
  echo -e "${GREEN}${1}${NORMAL}"
}

# All functions, I know they should be in a separated file, but they are here to keep all in one file 
# Receives binary name and url
function simple_install() {
  curl -sL --output ${BIN_DIR}/$1 $2
  chmod +x ${BIN_DIR}/$1
}

function ubuntu_packages()
{
  SUDO=''
  if (( $EUID != 0 )); then
    SUDO='sudo'
    [ "$(sudo id -u)" = "0" ] || { echo "You need sudo privileges to continue"; exit 1; } 
  fi
  ${SUDO} apt update
  ${SUDO} apt dist-upgrade -y
  ${SUDO} apt autoremove -y
  ${SUDO} apt install -y ${UBUNTU_PACKAGES[*]}
}

function install_gitlab_runner()
{
  simple_install gitlab-runner "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
}

function install_helm()
{
  LATEST_V3=$(curl -Ls https://github.com/helm/helm/releases | grep 'href="/helm/helm/releases/tag/v3.[0-9]*.[0-9]*\"' | grep -v no-underline | head -n 1 | cut -d '"' -f 2 | awk '{n=split($NF,a,"/");print a[n]}' | awk 'a !~ $0{print}; {a=$0}')
  curl -sLO https://get.helm.sh/helm-${LATEST_V3}-linux-amd64.tar.gz 
  tar zxvf helm-${LATEST_V3}-linux-amd64.tar.gz
  mv linux-amd64/helm ${BIN_DIR}
}

function install_kustomize()
{
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    mv kustomize ${BIN_DIR}
}

function install_skaffold()
{
  simple_install skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
}

function install_kubectl() 
{
  VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
  URL="https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/linux/amd64/kubectl"
  simple_install kubectl ${URL}
}

function install_kind()
{
  VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep tag_name | cut -d'"' -f4)
  URL="https://github.com/kubernetes-sigs/kind/releases/download/${VERSION}/kind-linux-amd64"
  simple_install kind ${URL}
}

function install_tekton_cli()
{
  VERSION=$(curl -s https://api.github.com/repos/tektoncd/cli/releases/latest | grep tag_name | cut -d'"' -f4)
  curl -sLO https://github.com/tektoncd/cli/releases/download/${VERSION}/tkn_${VERSION#?}_Linux_x86_64.tar.gz
  tar zxvf tkn_${VERSION#?}_Linux_x86_64.tar.gz -C ${BIN_DIR} tkn
}

function install_eksctl()
{
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  chmod +x /tmp/eksctl
  mv /tmp/eksctl ${BIN_DIR}
}


function configure_helper() 
{
  HELPER_LINE='source ${HOME}/.bash_helper.sh'
  cat > ${HOME}/.bash_helper.sh <<EOL
PATH=\${HOME}/bin:\${PATH}
source <(kustomize completion bash)
source <(helm completion bash)
source <(skaffold completion bash)
source <(kubectl completion bash)
source <(kind completion bash)
source <(tkn completion bash)
source <(eksctl completion bash)
source <(flux completion bash)
umask 022
export EDITOR=vim
EOL
  chmod +x ${HOME}/.bash_helper.sh
  grep -qxF "${HELPER_LINE}" ${HOME}/.bashrc || echo ${HELPER_LINE} >> ${HOME}/.bashrc
}

function install_terraform()
{
  TER_VER=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
  curl -sLO https://releases.hashicorp.com/terraform/${TER_VER}/terraform_${TER_VER}_linux_amd64.zip
  unzip terraform_${TER_VER}_linux_amd64.zip 
  mv terraform ${BIN_DIR}
}

function install_gcloud()
{
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1
  export CLOUDSDK_INSTALL_DIR=${BIN_DIR}
  curl https://sdk.cloud.google.com | bash 
}

function install_aws()
{
  curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip 
  aws/install -i ${BIN_DIR}/aws-cli -b ${BIN_DIR}
}

function install_flux()
{
  curl -sLO https://fluxcd.io/install.sh 
  bash install.sh ${BIN_DIR}
}

echo -e "- Installing tools, packages, and updates. Time for a ${BEER} or a ${TEACUP}"
declare -A STEPS=(
  [install_kustomize]="Kustomize"
  [install_gitlab_runner]="GitLab Runner"
  [install_helm]="Helm"
  [install_skaffold]="Scaffold"
  [install_kubectl]="Kubectl"
  [install_kind]="Kind"
  [install_tekton_cli]="Tekton CLI"
  [install_eksctl]="Eksctl"
  [configure_helper]="Shell Helper"
  [install_terraform]="Terraform"
  [install_gcloud]="Google Cloud CLI"
  [install_flux]="Flux CLI"
  [install_aws]="AWS CLI V2"
)


printf '  - %-30s' "Ubuntu Packages" && ubuntu_packages >${LOG_FILE} 2>&1 && ${OK} || ${NOK}

for STEP in "${!STEPS[@]}"
do
  printf '  - %-30s' "${STEPS[$STEP]}" && ${STEP} >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
done

cd ${HOME}
rm -fr ${TMP_DIR}
