data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "this" {
  name                   = var.aks_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  dns_prefix             = "${var.aks_name}-dns"
  local_account_disabled = true
  tags                   = var.tags

  default_node_pool {
    name                 = "default"
    vm_size              = var.vm_size
    vnet_subnet_id       = var.vnet_subnet_id
    auto_scaling_enabled = true
    min_count            = var.min_count
    max_count            = var.max_count
  }

  identity {
    type = "SystemAssigned"
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    outbound_type       = "loadBalancer"
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  dynamic "service_mesh_profile" {
    for_each = var.enable_istio ? [1] : []
    content {
      mode                             = "Istio"
      revisions                        = var.istio_revisions
      internal_ingress_gateway_enabled = false
      external_ingress_gateway_enabled = false
    }
  }
}
