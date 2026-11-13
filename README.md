# ⎈ Slim Kubernetes on Oracle Cloud (free tier)

Fork of [nce/oci-free-cloud-k8s](https://github.com/nce/oci-free-cloud-k8s),
trimmed and adapted for my own setup. Upstream's README and history still apply
for anything not covered here.

| | |
|---|---|
| Cloud | Oracle Cloud (OKE), region `eu-frankfurt-1` |
| Domain | `oci.marthy.xyz`, DNS in AWS Route53 |
| Secrets | HashiCorp Vault KV v2 (`secret/oci-k8s/*`) via External Secrets |
| Login | Microsoft Entra ID → Dex (OIDC) |
| GitOps | FluxCD |

## What it deploys

**Infra** (`terraform/infra`): an OKE cluster `k8s-cluster`, a VCN
(`10.0.0.0/16`) with two subnets, and a node pool of two
`VM.Standard.A1.Flex` ARM workers. The default size is 1 oCPU / 6 GB / 50 GB
boot volume per node (2 oCPUs / 12 GB in total), which fits the halved free tier
for accounts without a credit card. Override with `kubernetes_worker_ocpus`,
`kubernetes_worker_memory_gbs` and `kubernetes_worker_boot_volume_gbs`.

**Apps** (`gitops/core`, installed by Flux):

- external-secrets (store `vault`, HashiCorp Vault)
- external-dns (Route53) and cert-manager (Let's Encrypt, DNS-01 via Route53)
- envoy-gateway: Gateway API on the OCI flexible load balancer, with OIDC
  `SecurityPolicies`
- Dex with the Entra ID connector
- kube-prometheus-stack and Grafana (Entra login); Prometheus uses one 50Gi
  `oci-bv` volume with 40GB retention
- metrics-server, Flux notification webhook/alerts

Removed compared to upstream: Longhorn, Teleport, Lychee, S3-proxy, Cloudflare
and GitHub SSO.

## Setup

Client tools: `terraform` (>= 1.12), `oci` (with `oci setup config` done),
`kubectl`, `vault`, `az`.

### 1. Terraform state

State lives in OCI object storage. Create the bucket once and put your object
storage namespace in `terraform/infra/_terraform.tf` and
`terraform/config/_terraform.tf`:

```bash
oci os ns get
oci os bucket create --name terraform-state --versioning Enabled --compartment-id <ocid>  # skip if it exists; keys are prefixed oci-k8s/
```

### 2. Infra

```bash
cd terraform/infra
cat > terraform.tfvars <<EOF
compartment_id = "ocid1.tenancy.oc1..xxx"
tenancy_id     = "ocid1.tenancy.oc1..xxx"
ssh_public_key = "ssh-ed25519 AAAA..."
EOF
terraform init && terraform apply
```

This writes `terraform/.kube.config`.

### 3. Vault secrets

All values are KV v2 entries under `secret/oci-k8s/<name>` with the data
`{"value": "..."}`:

| Name | Used by |
|---|---|
| `aws-route53-access-key-id`, `aws-route53-secret-access-key` | external-dns, cert-manager (IAM user limited to the hosted zone) |
| `entra-dex-client-id`, `entra-dex-client-secret`, `entra-tenant-id` | Dex |
| `dex-grafana-client`, `dex-envoy-client-secret` | Dex clients for Grafana and Envoy |
| `prometheus-remote-write-htpasswd` | Prometheus remote write |
| `github-fluxcd-token`, `slack-fluxcd-token`, `SLACK_API_URL` | Flux notifications |
| `github-flux-webhook-token` | written by Terraform (`config`) |

External Secrets needs a token with read access to `secret/data/oci-k8s/*`.
Terraform (`config`) additionally needs write access to that path for the
webhook token. Don't use a root token for either.

### 4. Entra ID

Register an app with the redirect URI
`https://login.oci.marthy.xyz/dex/callback`, delegated Graph permissions
`openid profile email User.Read GroupMember.Read.All` (with admin consent), and
a client secret. Members of the Entra group `admin` become admins in Grafana.

### 5. Config and Flux

```bash
cd terraform/config
terraform init && terraform apply
```

Needs a `*.tfvars` with `compartment_id`, `tenancy_id`, `vault_address`,
`vault_token`, the GitHub token and GitHub App values for Flux. As upstream
notes, the first run may fail on the `ClusterSecretStore` until external-secrets
is deployed by Flux; rerun it afterwards.

For a feature branch, set the `ref` in the `FluxInstance` `sync` block to that
branch.

## Hardcoded values to review

- `ocid1.networksecuritygroup…` in `gitops/core/envoy-gateway/envoyproxy.yaml`
  is created by `terraform/config` (ingress module); update it after the first
  apply.
- Terraform backend namespace/bucket (see step 1).

## Upgrading Kubernetes

Run `terraform apply` in `terraform/infra`; it picks the highest available
version. Then roll the nodes with
[cycleNodes.sh](terraform/infra/cycleNodes.sh), which replaces one worker at a
time and waits for all nodes to be Ready.

See the [upstream README](https://github.com/nce/oci-free-cloud-k8s#readme) for
the full history of upgrade notes.
