terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# User Assigned Identity for the Service
resource "azurerm_user_assigned_identity" "service_identity" {
  name                = "${var.service_name}-identity-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Provision dedicated Kubernetes namespace for the service
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.service_name
    labels = {
      environment = var.environment
    }
  }
}

# Provision Service Account for AKS Workload Identity integration
resource "kubernetes_service_account" "this" {
  metadata {
    name      = "${var.service_name}-sa"
    namespace = kubernetes_namespace.this.metadata[0].name
    annotations = {
      "azure.workload.identity/client-id" = azurerm_user_assigned_identity.service_identity.client_id
    }
  }
}

# Federated Identity Credential for AKS Workload Identity
resource "azurerm_federated_identity_credential" "aks_workload" {
  name                = "${var.service_name}-aks-fed-${var.environment}"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.service_identity.id
  subject             = "system:serviceaccount:${kubernetes_namespace.this.metadata[0].name}:${kubernetes_service_account.this.metadata[0].name}"
}

# Role Binding: Bind service release Service Account to the shared httproute-writer ClusterRole
resource "kubernetes_role_binding" "httproute_writer" {
  metadata {
    name      = "${var.service_name}-httproute-writer"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "httproute-writer"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.this.metadata[0].name
    namespace = kubernetes_namespace.this.metadata[0].name
  }
}

# Role Assignment: Service Bus Data Receiver on specific topics
resource "azurerm_role_assignment" "servicebus_data_receiver" {
  for_each             = toset(var.servicebus_topic_receiver_ids)
  scope                = each.value
  role_definition_name = "Azure Service Bus Data Receiver"
  principal_id         = azurerm_user_assigned_identity.service_identity.principal_id
}

# Role Assignment: Service Bus Data Sender on specific topics
resource "azurerm_role_assignment" "servicebus_data_sender" {
  for_each             = toset(var.servicebus_topic_sender_ids)
  scope                = each.value
  role_definition_name = "Azure Service Bus Data Sender"
  principal_id         = azurerm_user_assigned_identity.service_identity.principal_id
}

# Role Assignment: Reader on the PostgreSQL server (control plane only).
# NOTE: This does NOT grant database-level access; that requires an Entra admin
# on the server plus in-database role grants.
# count uses a static flag instead of the server ID, which is unknown at plan time.
resource "azurerm_role_assignment" "postgres_reader" {
  count                = var.postgres_enabled ? 1 : 0
  scope                = var.postgres_server_id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.service_identity.principal_id
}
