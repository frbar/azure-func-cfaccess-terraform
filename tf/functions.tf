resource "azurerm_resource_group" "poc" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_application_insights" "poc" {
  name                = "${var.env_name}-application-insights"
  location            = azurerm_resource_group.poc.location
  resource_group_name = azurerm_resource_group.poc.name
  application_type    = "web"
}

resource "azurerm_storage_account" "poc" {
  name                     = "${var.env_name}func"
  resource_group_name      = azurerm_resource_group.poc.name
  location                 = azurerm_resource_group.poc.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "poc" {
  name                = "${var.env_name}-plan"
  resource_group_name = azurerm_resource_group.poc.name
  location            = azurerm_resource_group.poc.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_windows_function_app" "poc" {
  name                = "${var.env_name}-func"
  resource_group_name = azurerm_resource_group.poc.name
  location            = azurerm_resource_group.poc.location

  storage_account_name       = azurerm_storage_account.poc.name
  storage_account_access_key = azurerm_storage_account.poc.primary_access_key
  service_plan_id            = azurerm_service_plan.poc.id

  site_config {
    health_check_path = "/api/health"

    dynamic "ip_restriction" {
      for_each = data.cloudflare_ip_ranges.cloudflare_ips.ipv4_cidr_blocks
      content {
        action     = "Allow"
        ip_address = ip_restriction.value
      }
    }
  }

  app_settings = {
    "AzureWebJobsStorage"            = "DefaultEndpointsProtocol=https;AccountName=${azurerm_storage_account.poc.name};EndpointSuffix=core.windows.net;AccountKey=${azurerm_storage_account.poc.primary_access_key}"
    "SCM_DO_BUILD_DURING_DEPLOYMENT" = "0",
    "WEBSITE_RUN_FROM_PACKAGE"       = "1",
    "FUNCTIONS_WORKER_RUNTIME"       = "dotnet-isolated",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.poc.instrumentation_key,
    "FUNCTIONS_EXTENSION_VERSION"    = "~4",
    "AzureWebJobsDisableHomepage"    = "true"
  }

}

data "cloudflare_ip_ranges" "cloudflare_ips" {}
