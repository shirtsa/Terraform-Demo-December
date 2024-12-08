# Terraform provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.12.0"
    }
  }
    backend "azurerm" {
      resource_group_name = "StorageRG"
      storage_account_name = "taskboardstoragenik"
      container_name = "taskboardstorageniko"
      key = "terraform.tfstate"
    }
}

provider "azurerm" {
  subscription_id = "5062702a-fd6f-4383-bf74-1e2374bfb454"
  features {
  }
}

#Random Integer Number
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

#Resource Group
resource "azurerm_resource_group" "nikolarg" {
  location = var.resource_group_location
  name     = "${var.resource_group_name}-${random_integer.ri.result}"
}

#Service Plan
resource "azurerm_service_plan" "nikoasp" {
  name                = "${var.app_service_plan_name}-${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.nikolarg.name
  location            = azurerm_resource_group.nikolarg.location
  os_type             = "Linux"
  sku_name            = "F1"
}

#Web application
resource "azurerm_linux_web_app" "nikoalwp" {
  name                = "${var.app_service_name}${random_integer.ri.result}"
  resource_group_name = azurerm_resource_group.nikolarg.name
  location            = azurerm_service_plan.nikoasp.location
  service_plan_id     = azurerm_service_plan.nikoasp.id

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserverniko.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.nikoladatabase.name};User ID=${azurerm_mssql_server.sqlserverniko.administrator_login};Password=${azurerm_mssql_server.sqlserverniko.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }
}

#SQL server
resource "azurerm_mssql_server" "sqlserverniko" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.nikolarg.name
  location                     = azurerm_resource_group.nikolarg.location
  version                      = "12.0"
  administrator_login          = var.sql_user
  administrator_login_password = var.sql_user_password
}

#Database
resource "azurerm_mssql_database" "nikoladatabase" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sqlserverniko.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  zone_redundant = false
  sku_name       = "S0"
}

#FireWall Rule
resource "azurerm_mssql_firewall_rule" "nikofirewall" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.sqlserverniko.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

#Source Control - GitHub
resource "azurerm_app_service_source_control" "githubrepo" {
  app_id                 = azurerm_linux_web_app.nikoalwp.id
  repo_url               = var.github_repo
  branch                 = "main"
  use_manual_integration = true
}