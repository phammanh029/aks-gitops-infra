# AKS + Application Gateway for Containers + Flux demo

This Terraform root provisions only the infrastructure for a minimal AKS GitOps demo:

- AKS cluster
- Virtual network and subnets
- Application Gateway for Containers Azure resources
- AKS Flux configurations that sync external app repositories

The app services are intentionally in separate GitHub repositories. This repo should not contain application Deployment, Service, Gateway, or HTTPRoute manifests.

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
        gateway.yaml        # demo owner of the shared HTTP Gateway
        httproute.yaml      # recommended for routing to the Service

aks-gitops-admin/
  clusters/
    dev/
      admin/
        kustomization.yaml
        namespace.yaml
        deployment.yaml
        service.yaml
        httproute.yaml      # attaches to the shared Gateway from storefront
```

The app can be a simple echo container. Example images:

- `hashicorp/http-echo`
- `ealen/echo-server`
- `mendhak/http-https-echo`

Flux in this infra repo points at one or more external app repos through the `flux_repositories` map. Each map key becomes the Flux configuration name, so keep keys stable after apply.

Example with two separate app repos:

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

You can add more app repos by adding more entries to this map.

## Usage

Initialize with your Azure backend configuration:

```bash
terraform -chdir=terraform init \
  -backend-config="resource_group_name=<state-rg>" \
  -backend-config="storage_account_name=<state-storage-account>" \
  -backend-config="container_name=<state-container>" \
  -backend-config="key=aks-appgw-flux-dev.tfstate"
```

Plan:

```bash
terraform -chdir=terraform plan \
  -var-file="envs/dev.tfvars" \
  -var="resource_group_name=<demo-rg>" \
  -var="aks_name=<aks-name>" \
  -var="gateway_name=<appgw-containers-name>" \
  -var="vnet_name=<vnet-name>" \
  -var='flux_repositories={
    storefront={url="https://github.com/phammanh029/aks-gitops-storefront.git",path="./clusters/dev/storefront"},
    admin={url="https://github.com/phammanh029/aks-gitops-admin.git",path="./clusters/dev/admin"}
  }'
```

## Notes

- This repo assumes the Azure resource group already exists.
- `flux_repositories` must contain at least one app repository when `enable_flux = true`.
- Public HTTPS GitHub repos are simplest for demos. Private repos require Flux credentials and should not be hard-coded in tfvars.
- Terraform does not deploy the storefront/admin apps directly; Flux reconciles them from the external repositories.
- The external app manifests assume the Application Gateway for Containers GatewayClass/ALB controller is installed in the cluster. This Terraform root provisions the AKS cluster, VNet/subnets, Application Gateway for Containers Azure resources, and Flux wiring.
- Each external app repo should be small and disposable: Kustomize manifests only, with the app using a public echo container image.
