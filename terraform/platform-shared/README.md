# Platform Shared Infrastructure

This directory contains the shared platform infrastructure resources composed once per environment:
- AKS (Azure Kubernetes Service)
- Shared Service Bus
- Shared Redis
- Shared PostgreSQL server
- Gateway dependencies
- Private endpoints / DNS

## External Dependencies

This infrastructure consumes the existing hub-provided container registry (ACR) as an external dependency. The lifecycle (creation, deletion, updates) of this registry is managed externally.

### Required Variables

The following external registry reference inputs must be provided to the platform-shared module:
- `registry_name`: Name of the existing hub container registry
- `registry_login_server`: Login server URL of the existing hub container registry
- `registry_resource_id`: Resource ID of the existing hub container registry

A validation rule is enforced in `main.tf` to ensure these variables are supplied during planning/deployment, preventing fallback behavior that would implicitly attempt to create container registry resources.
