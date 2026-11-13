terraform {

  required_providers {

    vault = {
      source = "hashicorp/vault"
    }

    flux = {
      source = "fluxcd/flux"
    }

    github = {
      source  = "integrations/github"
      version = ">= 5.18.0"
    }
  }
}
