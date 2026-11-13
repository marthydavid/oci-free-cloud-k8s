data "github_repository" "oci" {
  full_name = "${var.gh_org}/${var.gh_repository}"
}

resource "random_password" "webhook_secret" {
  length  = 32
  special = false
}

resource "vault_kv_secret_v2" "webhook_token" {
  mount = var.vault_mount
  name  = "oci-k8s/github-flux-webhook-token"

  data_json = jsonencode({
    value = random_password.webhook_secret.result
  })
}

resource "github_repository_webhook" "flux_webhook" {
  repository = data.github_repository.oci.name

  configuration {
    url          = "https://flux-webhook.oci.marthy.xyz/hook/${sha256(format("%s%s%s", random_password.webhook_secret.result, "github-receiver", "flux-system"))}"
    content_type = "json"
    secret       = random_password.webhook_secret.result
    insecure_ssl = false
  }

  events = ["push"]
}
