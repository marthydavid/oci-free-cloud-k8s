provider "kubectl" {
  load_config_file = true
  config_path      = "../.kube.config"
}

provider "helm" {
  kubernetes = {
    config_path = "../.kube.config"
  }
}

provider "kubernetes" {
  config_path = "../.kube.config"
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}
