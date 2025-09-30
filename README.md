# Despliegue de una Azure Function con Terraform

Este repositorio contiene toda la configuración necesaria para desplegar una **Azure Function App** con un **HTTP trigger** escrito en Node.js, utilizando **Terraform** como herramienta de infraestructura como código.

La solución crea y relaciona automáticamente:

- Un *Resource Group* dedicado.
- Una *Storage Account* y un contenedor privado para el código.
- Un *App Service Plan* en el plan de consumo (SKU `Y1`).
- Una *Windows Function App* configurada para Node.js 18.
- Una función HTTP (`index.js`) lista para probar desde el navegador o `curl`.

## Requisitos previos

1. [Instalar Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.4.0`.
2. [Instalar Azure CLI](https://learn.microsoft.com/es-es/cli/azure/install-azure-cli).
3. Iniciar sesión en Azure con `az login` y seleccionar la suscripción correcta con `az account set --subscription "<SUBSCRIPTION_ID>"`.
4. *(Opcional)* Si usas GitHub Codespaces y ves que se inicia en **Recovery Container**, ejecuta el comando **Codespaces: Rebuild Container** una vez aplicados los cambios del archivo `.devcontainer/devcontainer.json`.

## Variables de entrada

| Variable          | Descripción                                                                 | Obligatoria | Valor por defecto |
|-------------------|-----------------------------------------------------------------------------|-------------|-------------------|
| `name_function`   | Prefijo identificador del proyecto. Se usa para generar el nombre del resto de recursos. | Sí          | —                 |
| `location`        | Región donde se desplegarán los recursos.                                   | No          | `westeurope`      |
| `allowed_origins` | Lista de orígenes permitidos para CORS.                                     | No          | `["*"]`          |
| `tags`            | Conjunto de etiquetas que se propagan a todos los recursos.                 | No          | `{}`              |

Puedes crear un archivo `terraform.tfvars` (o usar la plantilla incluida) con el siguiente contenido de ejemplo:

```hcl
name_function = "demo-func"
tags = {
  environment = "dev"
  owner       = "team-devops"
}
```

## Pasos para el despliegue

1. **Inicializar Terraform**
   ```bash
   terraform init
   ```
   Descarga los proveedores declarados y prepara el directorio de trabajo.

2. **Revisar el plan de ejecución**
   ```bash
   terraform plan -out tfplan
   ```
   Calcula los cambios necesarios y guarda el plan para su aplicación posterior.

3. **Aplicar los cambios**
   ```bash
   terraform apply tfplan
   ```
   Crea todos los recursos en Azure. Al finalizar, Terraform mostrará la URL para invocar la función.

4. **Probar la función**
   ```bash
   curl "$(terraform output -raw function_invocation_url)&name=Terraform"
   ```
   Deberías recibir un JSON con el identificador enviado en la query string.

5. **Destruir la infraestructura (opcional)**
   ```bash
   terraform destroy -auto-approve
   ```
   Elimina todos los recursos creados por el despliegue.

## Estructura del proyecto

```
├── example/
│   └── index.js        # Código de la Azure Function
├── main.tf             # Definición principal de recursos
├── outputs.tf          # Salidas útiles del despliegue
├── variables.tf        # Variables de entrada
└── versions.tf         # Versiones de Terraform y proveedores requeridos
```

## Notas adicionales

- Los nombres de los recursos se generan automáticamente añadiendo un sufijo aleatorio para evitar colisiones en Azure (especialmente en la Storage Account, cuyo nombre debe ser único a nivel global).
- El plan de servicio utiliza el SKU de consumo (`Y1`), ideal para workloads esporádicos o entornos de laboratorio. Puedes cambiarlo en `main.tf` si necesitas un plan dedicado.
- La Function App crea una identidad administrada del sistema; puedes usarla para dar permisos adicionales a otros recursos de Azure si tu función los necesita.
- No almacenes archivos de estado (`terraform.tfstate`) en repositorios públicos. Para trabajo colaborativo, configura un *backend* remoto (por ejemplo, Azure Storage) antes de ejecutar `terraform init`.
