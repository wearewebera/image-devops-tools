#!/usr/bin/env bash

function simple_install() # Receives binary name and url
{
  curl -sL --output ${BIN_DIR}/$1 $2
  chmod +x ${BIN_DIR}/$1
}

function install_ubuntu_packages()
{
  echo "- Requesting sudo privilege"
  [ "$(sudo id -u)" = "0" ] || { echo "You need sudo privileges to continue"; exit 1; } 
  sudo apt update
  sudo apt dist-upgrade -y
  sudo apt autoremove -y
  sudo apt install -y ${PACKAGES[*]}
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

function install_scaffold()
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
complete -C \${HOME}/bin/kustomize kustomize
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



# Start script
set -e
umask 022
export PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/sbin:

BIN_DIR=${HOME}/bin
TMP_DIR=${HOME}/tmp/workstation-tmp
PACKAGES=(
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

install_ubuntu_packages
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
