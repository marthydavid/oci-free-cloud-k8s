resource "kubectl_manifest" "external_secrets_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
YAML
}

resource "kubectl_manifest" "external_secrets_token" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: vault-token
  namespace: external-secrets
type: Opaque
data:
  token: ${base64encode(var.vault_token)}
YAML

  sensitive_fields = ["data"]
  depends_on       = [kubectl_manifest.external_secrets_namespace]
}

# HashiCorp Vault KV v2 mounted at "${var.vault_mount}"
resource "kubectl_manifest" "external_secrets_cluster_store" {
  yaml_body = <<YAML
apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: ${var.vault_address}
      path: ${var.vault_mount}
      version: v2
      auth:
        tokenSecretRef:
          name: vault-token
          key: token
          namespace: external-secrets
YAML

  depends_on = [kubectl_manifest.external_secrets_token]
}
