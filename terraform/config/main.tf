module "externalsecrets" {
  source = "./modules/external-secrets"

  vault_address = var.vault_address
  vault_token   = var.vault_token
  vault_mount   = var.vault_mount

  depends_on = [
    module.fluxcd
  ]
}

module "fluxcd" {
  source = "./modules/fluxcd"

  gh_token                   = var.gh_token
  vault_mount                = var.vault_mount
  compartment_id             = var.compartment_id
  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id
  github_app_pem             = var.github_app_pem
}

module "ingress" {
  source = "./modules/ingress"

  compartment_id = var.compartment_id
}

module "grafana" {
  source = "./modules/grafana"

  compartment_id = var.compartment_id
}
