# AKS + Flux GitOps demo

This Terraform root provisions only the infrastructure needed to test AKS GitOps:

- AKS cluster
- Virtual network and AKS subnet
- AKS Flux extension
- Flux configurations that sync external app repositories

No Application Gateway, Gateway API, HTTPRoute, or alerting/monitoring add-ons are configured by this Terraform root.

The AKS configuration is intentionally constrained for the demo environment limits:

- one default agent pool only
- `Standard_D2s_v3` nodes
- two nodes maximum
- Istio/service mesh disabled
- no alerting/monitoring add-ons configured by this Terraform root

The app services are intentionally in separate GitHub repositories. This repo should not contain application Deployment or Service manifests.

## External app repo contract

Create separate GitHub repos for the apps, for example:

```text
aks-gitops-storefront/
  clusters/
    dev/
      storefront/
        kustomization.yaml
        namespace.yaml
        deployment.yaml
        service.yaml

aks-gitops-admin/
  clusters/
    dev/
      admin/
        kustomization.yaml
        namespace.yaml
        configmap.yaml
        deployment.yaml
        service.yaml
```

Flux in this infra repo points at one or more external app repos through the `flux_repositories` map. Each map key becomes the Flux configuration name, so keep keys stable after apply.

Example:

```hcl
flux_repositories = {
  storefront = {
    url    = "ssh://git@github.com/phammanh029/aks-gitops-storefront.git"
    branch = "main"
    path   = "./clusters/dev/storefront"
  }

  admin = {
    url    = "ssh://git@github.com/phammanh029/aks-gitops-admin.git"
    branch = "main"
    path   = "./clusters/dev/admin"
  }
}
```

For private GitHub app repositories, set `generate_flux_ssh_keys = true`. Terraform then:

- generates one ED25519 SSH key per Flux repository,
- configures the AKS Flux configuration with the matching private key.
- outputs each public key as `flux_repository_deploy_public_keys`.

After apply, add each public key to the matching private GitHub app repository as a read-only deploy key. Flux may report authentication failures until the keys are added; it should recover on the next reconciliation after GitHub accepts the deploy keys.

Example dev settings:

```hcl
generate_flux_ssh_keys = true
```

The generated private keys are stored in Terraform state. Protect the AzureRM state backend as sensitive infrastructure secret storage.

## Usage

From the repository root, use the helper script for normal demo operations:

```bash
./deploy.sh plan
./deploy.sh apply
./deploy.sh verify
```

The script logs in with the Azure service principal, creates the demo resource group if needed, initializes the AzureRM Terraform backend, runs `fmt`/`validate`, and then runs Terraform plan/apply with `envs/dev.tfvars`.

Manual Terraform commands are also supported.

Initialize with your Azure backend configuration:

```bash
terraform -chdir=terraform init   -backend-config="resource_group_name=<state-rg>"   -backend-config="storage_account_name=<state-storage-account>"   -backend-config="container_name=<state-container>"   -backend-config="key=aks-flux-dev.tfstate"
```

Plan:

```bash
terraform -chdir=terraform plan   -var-file="envs/dev.tfvars"   -var="resource_group_name=<demo-rg>"   -var="aks_name=<aks-name>"   -var="vnet_name=<vnet-name>"
```

Apply:

```bash
terraform -chdir=terraform apply   -var-file="envs/dev.tfvars"   -var="resource_group_name=<demo-rg>"   -var="aks_name=<aks-name>"   -var="vnet_name=<vnet-name>"
terraform -chdir=terraform output -no-color flux_repository_deploy_public_keys
```

## Notes

- This repo assumes the Azure resource group already exists.
- `flux_repositories` must contain at least one app repository when `enable_flux = true`.
- Private GitHub repos use generated SSH deploy keys. Do not hard-code private keys, PATs, or credentialized HTTPS URLs in tfvars.
- Terraform does not deploy the storefront/admin apps directly; Flux reconciles them from the external repositories.
- The app repos intentionally use `ClusterIP` services only. Use `kubectl port-forward` to test them without ingress.
