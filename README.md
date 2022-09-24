# Webera Dev and Ops Tools Image

Repository used to maintain container image with collection of scripts and
tools useful to Devs and Ops. Besides the installation it also configures
the `.bashrc` file with a helper script which loads all the autocomplete for
the installed tools. To use this image:

    docker run --rm -it webera/devops-tools

## What about this container?
  - Kubectl
  - Flux CLI
  - Helm
  - Kustomize 
  - gcloud
  - AWS CLI v2
  - Terraform
  - Skaffold
  - Kind
  - Tekton CLI
  - eksctl
  - ArgoCD CLI
  - GitLab Runnner
  - Github CLI
  - FZF
  - neovim

## Python Virtual Environment

The scripts creates a personal `.venv` environment on the home folder and adds
to the `.bashrc` script using the helper script.

[See on Docker HUB.](https://hub.docker.com/r/webera/devops-tools)
