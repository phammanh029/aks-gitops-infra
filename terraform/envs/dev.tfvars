# Environment variable overrides for dev
environment = "dev"

generate_flux_ssh_keys = true

flux_repositories = {
  storefront = {
    url  = "ssh://git@github.com/phammanh029/aks-gitops-storefront.git"
    path = "./clusters/dev/storefront"
  }

  admin = {
    url  = "ssh://git@github.com/phammanh029/aks-gitops-admin.git"
    path = "./clusters/dev/admin"
  }
}
