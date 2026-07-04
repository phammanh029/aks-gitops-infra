# Terraform Architecture & Directory Layout

This directory uses the **Single Root + tfvars** pattern to eliminate HCL duplication across environments while preserving strict state isolation.

## Architecture & How it Works

Rather than duplicating root module wiring across separate environment folders, all platform and service composition is defined once in:
- `terraform/main.tf` — Root composition module
- `terraform/variables.tf` — Root input variables

Environment-specific overrides and variable definitions are stored in thin variable files under `terraform/envs/`:
- `terraform/envs/dev.tfvars` — Development environment values
- `terraform/envs/qa.tfvars` — QA environment values
- `terraform/envs/prod.tfvars` — Production environment values

## CI/CD Pipeline Execution

In automated workflows (`deploy.yml` and `terraform.yml`), Terraform is executed from the `terraform/` working directory with dynamic backend and variable file flags:
1. **Init**: Initializes the backend for the target environment using dynamic Azure Blob storage keys:
   ```bash
   terraform -chdir="terraform" init -backend-config="key=platform-<env>.tfstate" ...
   ```
2. **Plan & Apply**: Passes the environment-specific `.tfvars` file:
   ```bash
   terraform -chdir="terraform" plan -var-file="envs/<env>.tfvars" -input=false
   ```

## Directory Structure

- `main.tf` / `variables.tf`: Single root composition wiring together shared resources and services.
- `envs/{dev,qa,prod}.tfvars`: Environment-specific variable definition files.
- `platform-shared/`: Composition module for shared resources (AKS, PostgreSQL, Redis, Service Bus, Gateway).
- `services/{admin,storefront,erp-connector}/`: Per-service compositions combining generic baseline identity/RBAC with service-specific Azure resources.
- `modules/`: Reusable, environment-agnostic resource building blocks (`postgres`, `redis`, `servicebus`, `blob`, `service`).

For full architectural context and decision records, refer to:
- [docs/README.md](../docs/README.md)
- [docs/adr/0003-terraform-environment-and-module-layout.md](../docs/adr/0003-terraform-environment-and-module-layout.md)
