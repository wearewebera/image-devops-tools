# Webera Dev and Ops Tools Image

Repository used to maintain container image with collection of scripts and
tools useful to Devs and Ops. Besides the installation it also configures
the `.bashrc` file with a helper script which loads all the autocomplete for
the installed tools.

This script is kinda of idempotent, you can run it multiple times and it will
only update the binaries and packages, except for gcloud and AWS CLI, because
they have their own update processes.

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
  - FZF
  - neovim

## Python Virtual Environment

The scripts creates a personal `.venv` environment on the home folder and adds
to the `.bashrc` script using the helper script.

[See on Docker HUB.](https://hub.docker.com/r/webera/devops-tools)
