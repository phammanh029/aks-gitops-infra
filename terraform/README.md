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
    url    = "https://github.com/phammanh029/aks-gitops-storefront.git"
    branch = "main"
    path   = "./clusters/dev/storefront"
  }

  admin = {
    url    = "https://github.com/phammanh029/aks-gitops-admin.git"
    branch = "main"
    path   = "./clusters/dev/admin"
  }
}
```

## Usage

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
```

## Notes

- This repo assumes the Azure resource group already exists.
- `flux_repositories` must contain at least one app repository when `enable_flux = true`.
- Public HTTPS GitHub repos are simplest for demos. Private repos require Flux credentials and should not be hard-coded in tfvars.
- Terraform does not deploy the storefront/admin apps directly; Flux reconciles them from the external repositories.
- The app repos intentionally use `ClusterIP` services only. Use `kubectl port-forward` to test them without ingress.
