# storefront service composition

Terraform composition for Azure resources used only by
`jtl-platform-shop-storefront`.

This directory calls `terraform/modules/service` for the shared service
baseline, then adds storefront-only Azure resources when required. Shared Redis,
Service Bus, PostgreSQL server, and Gateway dependencies come from
`terraform/platform-shared`.

Do not place storefront Kubernetes Deployments, HPAs, HTTPRoutes, or application
manifests here. Those stay in the storefront service repository.
