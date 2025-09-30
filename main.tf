provider "azurerm" {
  features {}
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

locals {
  base_name             = lower(replace(var.name_function, "[^0-9a-zA-Z]", ""))
  suffix                = random_integer.suffix.result
  resource_group_name   = "${var.name_function}-rg-${local.suffix}"
  service_plan_name     = "${var.name_function}-plan-${local.suffix}"
  function_app_name     = "${var.name_function}-fa-${local.suffix}"
  function_name         = "${var.name_function}-http"
  storage_account_name  = substr(lower(replace("${local.base_name}${local.suffix}", "[^0-9a-z]", "")), 0, 24)
  storage_container_name = "functions"
}

resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

resource "azurerm_storage_container" "code" {
  name                  = local.storage_container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_service_plan" "sp" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1"

  tags = var.tags
}

resource "azurerm_windows_function_app" "wfa" {
  name                       = local.function_app_name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id
  functions_extension_version = "~4"

  site_config {
    application_stack {
      node_version = "~18"
    }
    cors {
      allowed_origins     = var.allowed_origins
      support_credentials = false
    }
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_function_app_function" "faf" {
  name            = local.function_name
  function_app_id = azurerm_windows_function_app.wfa.id
  language        = "JavaScript"

  file {
    name    = "index.js"
    content = file("example/index.js")
  }

  test_data = jsonencode({
    name = "Azure"
  })

  config_json = jsonencode({
    bindings = [
      {
        authLevel = "anonymous"
        type      = "httpTrigger"
        direction = "in"
        name      = "req"
        methods   = ["get", "post"]
      },
      {
        type      = "http"
        direction = "out"
        name      = "res"
      }
    ]
  })
}
