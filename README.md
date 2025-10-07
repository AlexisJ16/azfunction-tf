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

4. **Probar la función** (ver sección "Cómo probar la funcionalidad" más abajo para más detalles)
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
│   └── index.js            # Código de la Azure Function
├── main.tf                 # Definición principal de recursos
├── outputs.tf              # Salidas útiles del despliegue
├── variables.tf            # Variables de entrada
├── versions.tf             # Versiones de Terraform y proveedores requeridos
├── test-function.sh        # Script para probar la función desplegada
└── terraform.tfvars.example # Plantilla de configuración
```

## Cómo probar la funcionalidad

Una vez desplegada la infraestructura, hay varias formas de probar tu Azure Function:

### Opción rápida: Usar el script de pruebas

Este repositorio incluye un script bash que ejecuta todas las pruebas automáticamente:

```bash
./test-function.sh
```

El script:
- Verifica que Terraform esté inicializado y desplegado
- Obtiene automáticamente la URL de la función
- Ejecuta tres tipos de pruebas (sin parámetros, GET con query string, POST con JSON)
- Muestra las respuestas de forma clara
- Proporciona comandos útiles para debugging

### 1. Probar desde la línea de comandos con curl

Después de ejecutar `terraform apply`, obtén la URL de la función:

```bash
# Ver todas las salidas
terraform output

# O obtener solo la URL de invocación
terraform output -raw function_invocation_url
```

**Prueba con parámetro en query string:**
```bash
curl "$(terraform output -raw function_invocation_url)&name=Terraform"
```

**Respuesta esperada:**
```json
{"id":"Terraform","message":"Hola Terraform, tu función está activa."}
```

**Prueba con POST y body JSON:**
```bash
curl -X POST "$(terraform output -raw function_invocation_url)" \
  -H "Content-Type: application/json" \
  -d '{"name":"DevOps"}'
```

**Respuesta esperada:**
```json
{"id":"DevOps","message":"Hola DevOps, tu función está activa."}
```

**Prueba sin parámetros:**
```bash
curl "$(terraform output -raw function_invocation_url)"
```

**Respuesta esperada:**
```
This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response.
```

### 2. Probar desde el navegador

1. Copia la URL de invocación:
   ```bash
   terraform output function_invocation_url
   ```

2. Pégala en tu navegador y añade el parámetro `name`:
   ```
   https://[tu-function-app].azurewebsites.net/api/[nombre-funcion]?name=Usuario
   ```

3. Deberías ver la respuesta JSON directamente en el navegador.

### 3. Probar desde Azure Portal

1. Inicia sesión en [Azure Portal](https://portal.azure.com)
2. Navega a tu Function App (el nombre se muestra en `terraform output function_app_name`)
3. En el menú lateral, selecciona **Functions**
4. Haz clic en tu función HTTP
5. Selecciona la pestaña **Code + Test**
6. Haz clic en **Test/Run** en la parte superior
7. En el panel de prueba:
   - Selecciona método **GET** o **POST**
   - Si usas GET, añade un parámetro de consulta: `name=Test`
   - Si usas POST, añade un body JSON: `{"name":"Test"}`
8. Haz clic en **Run** y verifica la respuesta

### 4. Monitorear logs en tiempo real

Para ver los logs de la función mientras la pruebas:

```bash
# Obtener el nombre de la Function App
az functionapp list --resource-group $(terraform output -raw resource_group_name) --query "[0].name" -o tsv

# Ver logs en tiempo real
az webapp log tail --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name)
```

### 5. Probar con herramientas como Postman o Insomnia

1. Crea una nueva petición
2. Método: `GET` o `POST`
3. URL: Pega la URL obtenida de `terraform output`
4. Para POST, añade un body JSON:
   ```json
   {
     "name": "TestUser"
   }
   ```
5. Envía la petición y verifica la respuesta

### Solución de problemas comunes

**Error: "Function not found" o 404**
- Espera 1-2 minutos después del despliegue para que la función esté completamente activa
- Verifica que la URL incluya el código de función si es necesario
- Ejecuta `terraform refresh` para actualizar el estado

**Error: "The service is unavailable"**
- La Function App puede estar iniciándose. Espera unos segundos e intenta de nuevo
- Verifica el estado en Azure Portal

**No recibo respuesta o timeout**
- Revisa los logs de la función usando Azure CLI o el portal
- Verifica que el grupo de seguridad de red o firewall no esté bloqueando las peticiones

**Para ver más detalles de depuración:**
```bash
# Ver el estado de la función
az functionapp show --name $(terraform output -raw function_app_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --query "{name:name,state:state,defaultHostName:defaultHostName}"
```

## Notas adicionales

- Los nombres de los recursos se generan automáticamente añadiendo un sufijo aleatorio para evitar colisiones en Azure (especialmente en la Storage Account, cuyo nombre debe ser único a nivel global).
- El plan de servicio utiliza el SKU de consumo (`Y1`), ideal para workloads esporádicos o entornos de laboratorio. Puedes cambiarlo en `main.tf` si necesitas un plan dedicado.
- La Function App crea una identidad administrada del sistema; puedes usarla para dar permisos adicionales a otros recursos de Azure si tu función los necesita.
- No almacenes archivos de estado (`terraform.tfstate`) en repositorios públicos. Para trabajo colaborativo, configura un *backend* remoto (por ejemplo, Azure Storage) antes de ejecutar `terraform init`.
