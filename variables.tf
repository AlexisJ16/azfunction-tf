variable "name_function" {
  type        = string
  description = "Prefijo base para nombrar los recursos del Function App."
}

variable "location" {
  type        = string
  description = "Región de Azure donde se desplegarán los recursos."
  default     = "westeurope"
}

variable "allowed_origins" {
  type        = list(string)
  description = "Lista de orígenes permitidos para CORS en la Function App."
  default     = ["*"]
}

variable "tags" {
  type        = map(string)
  description = "Etiquetas comunes que se aplicarán a todos los recursos."
  default     = {}
}
