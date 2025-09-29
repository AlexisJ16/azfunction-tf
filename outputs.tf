output "function_invocation_url" {
  description = "URL para invocar la función HTTP desplegada."
  value       = azurerm_function_app_function.faf.invocation_url
}

output "resource_group_name" {
  description = "Nombre del resource group creado."
  value       = azurerm_resource_group.rg.name
}

output "function_app_name" {
  description = "Nombre de la Function App creada."
  value       = azurerm_windows_function_app.wfa.name
}
