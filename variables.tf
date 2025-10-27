variable "name_function" {
  type        = string
  description = "Name Function"
}

variable "location" {
  type        = string
  default     = "West Europe"
  description = "Location"
}

# Optional: explicitly set the Azure Subscription ID used by the provider.
# If not provided, the provider will try to use the Azure CLI context.
variable "subscription_id" {
  type        = string
  default     = null
  description = "Azure Subscription ID to use for deployments"
}