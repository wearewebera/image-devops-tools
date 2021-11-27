# Dev and Ops Tools

Collection of scripts and tools to improve dev and ops workflows. Besides the
installation it also configures the `.bashrc` file with a helper script which
loads all the autocomplete for the installed tools.

This script is kinda of idempotent, you can run it multiple times and it will
only update the binaries and packages, except for gcloud and AWS CLI, because
they have their own update processes.

## Tools
* GitLab Runnner
* Helm
* Kustomize 
* Kubectl
* Skaffold
* Kind
* Tekton CLI
* eksctl
* Terraform
* gcloud
* AWS CLI v2
* Flux CLI
* ArgoCD CLI
* FZF
* neovim

## Python Virtual Environment

The scripts creates a personal `.venv` environment on the home folder and adds
to the `.bashrc` script using the helper script.
