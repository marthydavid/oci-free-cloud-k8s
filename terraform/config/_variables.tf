variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
}

variable "region" {
  description = "OCI region"
  type        = string

  default = "eu-frankfurt-1"
}

variable "public_subnet_id" {
  type        = string
  description = "The public subnet's OCID"
}

variable "node_pool_id" {
  description = "The OCID of the Node Pool where the compute instances reside"
  type        = string
}

variable "tenancy_id" {
  description = "Tenancy OCID"
  type        = string
}

variable "gh_token" {
  description = "Github PAT for FluxCD"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "github_app_pem" {
  description = "The contents of the GitHub App private key PEM file"
  sensitive   = true
  type        = string
}

variable "vault_address" {
  type        = string
  description = "Address of the HashiCorp Vault server"
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
