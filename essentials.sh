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
)

mkdir -p ${BIN_DIR} ${TMP_DIR}
cd ${TMP_DIR}

# All functions, I know they should be in a separated file, but they are here to keep all in one file 
# Receives binary name and url
function simple_install() {
  curl -sL --output ${BIN_DIR}/$1 $2
  chmod +x ${BIN_DIR}/$1
}

function install_ubuntu_packages()
{
  echo -e "- Installing Ubuntu packages...time for a ${BEER} or a ${TEACUP}"
  SUDO=''
  if (( $EUID != 0 )); then
    SUDO='sudo'
    [ "$(sudo id -u)" = "0" ] || { echo "You need sudo privileges to continue"; exit 1; } 
  fi
  echo -n "  - Updating local apt database... " && ${SUDO} apt update >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
  echo -n "  - Performing distro upgrade... " && ${SUDO} apt dist-upgrade -y >${LOG_FILE} 2>&1 && ${OK} || ${NKK}
  echo -n "  - Clean up unecessary packages... " && ${SUDO} apt autoremove -y >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
  echo -n "  - Install all required packages... " && ${SUDO} apt install -y ${UBUNTU_PACKAGES[*]} >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_gitlab_runner()
{
  echo -n "- Installing GitLab Runner... " 
  simple_install gitlab-runner "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64" > ${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_helm()
{
  echo -e "- Installing Helm... " 
  LATEST_V3=$(curl -Ls https://github.com/helm/helm/releases | grep 'href="/helm/helm/releases/tag/v3.[0-9]*.[0-9]*\"' | grep -v no-underline | head -n 1 | cut -d '"' -f 2 | awk '{n=split($NF,a,"/");print a[n]}' | awk 'a !~ $0{print}; {a=$0}') 2>${LOG_FILE}
  echo -n "  - Download latest version 3... " && curl -sLO https://get.helm.sh/helm-${LATEST_V3}-linux-amd64.tar.gz >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
  echo -n "  - Uncompressing Helm and moving to the binaries folder... " 
  {
    tar zxvf helm-${LATEST_V3}-linux-amd64.tar.gz
    mv linux-amd64/helm ${BIN_DIR}
  } >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_kustomize()
{
  echo -n "- Installing Kustomize... "
  {
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    mv kustomize ${BIN_DIR}
  } >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_scaffold()
{
  echo -n "- Installing Scaffold... "
  simple_install skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64 >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_kubectl() 
{
  echo -n "- Installing Kubectl... "
  {
    VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    URL="https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/linux/amd64/kubectl"
    simple_install kubectl ${URL}
  } >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_kind()
{
  echo -n "- Installing Kind... "
  {
    VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep tag_name | cut -d'"' -f4)
    URL="https://github.com/kubernetes-sigs/kind/releases/download/${VERSION}/kind-linux-amd64"
    simple_install kind ${URL}
  } >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_tekton_cli()
{
  echo -n "- Installing Tekton CLI... "
  {
    VERSION=$(curl -s https://api.github.com/repos/tektoncd/cli/releases/latest | grep tag_name | cut -d'"' -f4)
    curl -sLO https://github.com/tektoncd/cli/releases/download/${VERSION}/tkn_${VERSION#?}_Linux_x86_64.tar.gz
    tar zxvf tkn_${VERSION#?}_Linux_x86_64.tar.gz -C ${BIN_DIR} tkn
  } >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
}

function install_eksctl()
{
  echo -n "- Installing Eksctl... "
  {
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    chmod +x /tmp/eksctl
    mv /tmp/eksctl ${BIN_DIR}
  } >${LOG_FILE} 2>&1 && ${OK} || ${NOK}
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
umask 022
EOL
  chmod +x ${HOME}/.bash_helper.sh
  grep -qxF "${HELPER_LINE}" ${HOME}/.bashrc || echo ${HELPER_LINE} >> ${HOME}/.bashrc
}




install_ubuntu_packages
install_kustomize
install_gitlab_runner
install_helm
install_scaffold
install_kubectl
install_kind
install_tekton_cli
install_eksctl
configure_helper

cd ${HOME}
rm -fr ${TMP_DIR}
