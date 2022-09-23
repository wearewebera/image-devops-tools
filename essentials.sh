#!/usr/bin/env bash
[ "${BASH_VERSINFO:-0}" -ge 4 ] || { echo "Upgrade your bash to at least version 4"; exit 1; }

set -eux
umask 022

# Configuration definitions
export DEFAULT_PYTHON_VERSION="${PYTHON_VERSION:-3}"
export BIN_DIR=${HOME}/bin
export TMP_DIR=${HOME}/tmp/workstation-tmp
export PATH=${BIN_DIR}:/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/sbin:/usr/local/sbin:
export UBUNTU_PACKAGES=(
  apt-utils
  docker.io
  vim
  build-essential
  git
  golang
  curl
  wget
  python${DEFAULT_PYTHON_VERSION}
  python${DEFAULT_PYTHON_VERSION}-dev
  python${DEFAULT_PYTHON_VERSION}-venv
  software-properties-common
  unzip
  jq
  fzf
)

mkdir -p ${BIN_DIR} ${TMP_DIR}
cd ${TMP_DIR}

# All functions, I know they should be in a separated file, but they are here to keep all in one file 
function ubuntu_packages()
{
  SUDO=''
  if (( $EUID != 0 )); then
    SUDO='sudo'
    [ "$(sudo id -u)" = "0" ] || { echo "You need sudo privileges to continue"; exit 1; } 
  fi
  ${SUDO} apt-get update
  ${SUDO} apt-get dist-upgrade -y
  ${SUDO} apt-get autoremove -y
  ${SUDO} apt-get install -y --no-install-recommends ${UBUNTU_PACKAGES[*]}
}

function install_gitlab_runner()
{
  curl -sL --output ${BIN_DIR}/gitlab-runner "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
  chmod +x ${BIN_DIR}/gitlab-runner
}

function install_helm()
{
  export USE_SUDO="false"
  export HELM_INSTALL_DIR="${BIN_DIR}"
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  bash -x get_helm.sh
}

function install_kustomize()
{
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
    mv kustomize ${BIN_DIR}
}

function install_skaffold()
{
  curl -sL --output ${BIN_DIR}/skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
  chmod +x ${BIN_DIR}/skaffold
}

function install_kubectl() 
{
  VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
  URL="https://storage.googleapis.com/kubernetes-release/release/${VERSION}/bin/linux/amd64/kubectl"
  curl -sL --output ${BIN_DIR}/kubectl ${URL}
  chmod +x ${BIN_DIR}/kubectl
}

function install_kind()
{
  VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | grep tag_name | cut -d'"' -f4)
  URL="https://github.com/kubernetes-sigs/kind/releases/download/${VERSION}/kind-linux-amd64"
  curl -sL --output ${BIN_DIR}/kind ${URL}
  chmod +x ${BIN_DIR}/kind
}

function install_tekton_cli()
{
  VERSION=$(curl -s https://api.github.com/repos/tektoncd/cli/releases/latest | grep tag_name | cut -d'"' -f4)
  curl -sLO https://github.com/tektoncd/cli/releases/download/${VERSION}/tkn_${VERSION#?}_Linux_x86_64.tar.gz
  tar zxvf tkn_${VERSION#?}_Linux_x86_64.tar.gz -C ${BIN_DIR} tkn
  [ -x ${BIN_DIR}/tkn ] || { echo "Error on tekton"; exit 1; }
}

function install_eksctl()
{
  curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  chmod +x /tmp/eksctl
  mv /tmp/eksctl ${BIN_DIR}
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
  [ -d ${HOME}/opt/google-cloud-sdk ] && return
  mkdir -p ${HOME}/opt
  export CLOUDSDK_CORE_DISABLE_PROMPTS=1
  export CLOUDSDK_INSTALL_DIR=${HOME}/opt
  curl https://sdk.cloud.google.com | bash 
  ${HOME}/opt/google-cloud-sdk/install.sh --quiet --bash-completion true  --path-update true
  source ${HOME}/opt/google-cloud-sdk/path.bash.inc
  gcloud components install -q gke-gcloud-auth-plugin
}

function install_aws()
{
  [ -d ${HOME}/opt/aws-cli ] && return
  mkdir -p ${HOME}/opt
  curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip 
  aws/install -i ${HOME}/opt/aws-cli -b ${BIN_DIR}
}

function install_flux()
{
  curl -sLO https://fluxcd.io/install.sh 
  bash install.sh ${BIN_DIR}
}

function install_argocd()
{
  VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  curl -sLo ${BIN_DIR}/argocd https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
  chmod +x ${BIN_DIR}/argocd
}

function configure_helper() 
{
  HELPER_LINE='source ${HOME}/.bash_helper.sh'
  cat > ${HOME}/.bash_helper.sh <<EOL
PATH=\${HOME}/bin:\${HOME}/opt/nvim-linux64/bin:\${PATH}
source <(kustomize completion bash)
source <(helm completion bash)
source <(skaffold completion bash)
source <(kubectl completion bash)
source <(kind completion bash)
source <(tkn completion bash)
source <(eksctl completion bash)
source <(flux completion bash)
source <(argocd completion bash)
complete -C \${HOME}/bin/aws_completer aws
alias vim=nvim
alias vi=nvim
umask 022
export EDITOR=nvim
export VIRTUAL_ENV_DISABLE_PROMPT=1
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
[ -f ~/.venv/bin/activate ] && source ~/.venv/bin/activate
EOL
  chmod +x ${HOME}/.bash_helper.sh
  grep -qxF "${HELPER_LINE}" ${HOME}/.bashrc || echo ${HELPER_LINE} >> ${HOME}/.bashrc
}

function python_venv()
{
  python${DEFAULT_PYTHON_VERSION} -m venv ${HOME}/.venv
}

function install_nvim()
{
  mkdir -p ${HOME}/opt
  wget https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz
  tar zxvf nvim-linux64.tar.gz -C ${HOME}/opt
}

function install_ghcli()
{
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install gh -y
}

declare STEPS=(
  ubuntu_packages
  install_kustomize
  install_gitlab_runner
  install_helm
  install_skaffold
  install_kubectl
  install_kind
  install_tekton_cli
  install_eksctl
  install_terraform
  install_gcloud
  install_aws
  install_flux
  install_argocd
  install_nvim
  install_ghcli
  configure_helper
  python_venv
)


for STEP in "${STEPS[@]}"
do
  ${STEP} 
done

cd ${HOME}
rm -fr ${TMP_DIR}
