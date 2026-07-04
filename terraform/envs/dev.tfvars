# Environment variable overrides for dev
environment = "dev"

flux_repositories = {
  storefront = {
    url  = "https://github.com/phammanh029/aks-gitops-storefront.git"
    path = "./clusters/dev/storefront"
  }

  admin = {
    url  = "https://github.com/phammanh029/aks-gitops-admin.git"
    path = "./clusters/dev/admin"
  }
}
