# service module

Generic per-service baseline used by every deployable service composition.

This module should create or grant:

- Kubernetes namespace boundary
- user-assigned managed identity
- GitHub OIDC federated credential for the service repository/environment
- AKS Workload Identity federated credential for service accounts in the namespace
- namespace-local HTTPRoute Role/RoleBinding
- scoped grants to shared resources such as Service Bus, Redis, PostgreSQL, and Key Vault

Service-specific resources such as admin-only Blob storage are composed by
`terraform/services/<service>` after calling this baseline module.
