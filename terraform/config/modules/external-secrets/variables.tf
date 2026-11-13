variable "vault_address" {
  type        = string
  description = "Address of the HashiCorp Vault server, e.g. https://vault.example.com:8200"
}

variable "vault_token" {
  type        = string
  description = "Vault token with read access to the KV mount"
  sensitive   = true
}

variable "vault_mount" {
  type        = string
  description = "Mount path of the KV v2 secrets engine"
  default     = "secret"
}
