## Azure Function HTTP con Terraform (Node.js)

Este proyecto despliega una Azure Function (HTTP trigger) en un Plan de Consumo usando Terraform y Node.js 18. Incluye todo para aplicar, probar con curl y destruir la infraestructura cuando termines.

## Arquitectura creada

- Resource Group
- Storage Account (requerido por Azure Functions)
- App Service Plan (Y1 Consumo)
- Windows Function App (Functions v4 + Node.js ~18)
- Function HTTP (trigger GET/POST, authLevel: anonymous)

## Requisitos previos

- Terraform 1.6+ (o superior)
- Azure CLI 2.50+ (o superior)
- Acceso a una suscripción de Azure con rol Contributor

Verifica herramientas instaladas:

```bash
terraform -version
az version
```

Inicia sesión en Azure y selecciona la suscripción:

```bash
az login
az account list --output table
az account set --subscription <SUBSCRIPTION_ID>
```

## Estructura del repo

```
main.tf
variables.tf
outputs.tf
terraform.tfvars         # valores locales (git-ignored)
example/
  index.js               # código de la función HTTP (Node.js)
```

## Configuración

Variables expuestas en `variables.tf`:

- `name_function` (string): base del nombre de los recursos.
- `location` (string): región de Azure. Por defecto "West Europe"; recomendado para Colombia: "Brazil South".
- `subscription_id` (string, opcional): ID de suscripción. Si no lo pones, el provider intentará usar el contexto de `az login`.

Importante sobre los nombres:

- Los nombres de Function App y Storage Account deben ser únicos globalmente y en minúsculas. Este proyecto genera automáticamente un sufijo aleatorio para evitar colisiones y cumplir restricciones. Tu `name_function` se usa como base.

Ejemplo de `terraform.tfvars` (recomendado para Colombia):

```hcl
name_function   = "myfunctionapp12345"
location        = "Brazil South"
subscription_id = "<TU_SUBSCRIPTION_ID>"
```

> Sugerencia: deja `subscription_id` explícito para evitar problemas de contexto dentro de contenedores.

## Despliegue

Inicializa y valida:

```bash
terraform init -upgrade
terraform validate
```

Previsualiza cambios:

```bash
terraform plan -var-file="terraform.tfvars"
```

Aplica la infraestructura:

```bash
terraform apply -var-file="terraform.tfvars"
```

Al finalizar, obtén la URL de la función:

```bash
terraform output -raw url
```

Ejemplo de salida:

```
https://<functionapp-unico>.azurewebsites.net/api/<function-name>
```

## Pruebas de funcionamiento

Guarda la URL en una variable local opcionalmente:

```bash
URL=$(terraform output -raw url)
```

1) GET sin parámetros (mensaje por defecto):

```bash
curl -i "$URL"
```

Respuesta esperada (200 + JSON):

```json
{"message":"This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."}
```

2) GET con parámetro `name`:

```bash
curl -s "$URL?name=Colombia"
```

Respuesta esperada:

```json
{"id":"Colombia"}
```

3) POST con JSON:

```bash
curl -s -X POST "$URL" -H "Content-Type: application/json" -d '{"name":"Terraform"}'
```

Respuesta esperada:

```json
{"id":"Terraform"}
```

## Verificación en Azure Portal (opcional)

- Resource Groups: https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups
- Function App: busca el nombre mostrado en el plan/app (se agrega sufijo aleatorio automáticamente).

## Modificar la función y volver a desplegar

Edita `example/index.js` y vuelve a aplicar:

```bash
terraform apply -var-file="terraform.tfvars"
```

Notas:

- La función expone siempre JSON y el header `Content-Type: application/json`.
- El nombre interno de la función agrega el sufijo `fn` para evitar conflictos al recrearla.

## Destruir la infraestructura (limpieza)

Cuando termines y quieras evitar costos:

```bash
terraform destroy -var-file="terraform.tfvars" -auto-approve
```

## Solución de problemas

1) Error: `subscription ID could not be determined and was not specified`

- Asegúrate de iniciar sesión y seleccionar suscripción:

```bash
az login
az account set --subscription <SUBSCRIPTION_ID>
```

- O define el `subscription_id` en `terraform.tfvars` (recomendado), o exporta variables de entorno antes del plan/apply:

```bash
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
# Opcional si te lo pide:
export ARM_TENANT_ID="<TENANT_ID>"
```

2) Error de nombre duplicado (Function App/Storage Account)

- Este proyecto añade un sufijo aleatorio para asegurar unicidad. Si cambias esta lógica, recuerda que Storage Account debe ser 3–24 chars, solo minúsculas y números, y único global.

3) Permisos insuficientes

- Verifica que tu usuario tenga rol Contributor en la suscripción o grupo de recursos.

4) Región

- Para Colombia, "Brazil South" suele ofrecer buena latencia. Alternativas: "East US 2". Usa nombres exactos de región.

## Detalles técnicos relevantes

- Provider: `azurerm` con `features {}` y soporte para `subscription_id`.
- Stack: Functions v4, Node.js `~18`.
- Plan: Consumo (`sku_name = "Y1"`).
- Salidas: `url` corresponde a la `invocation_url` de la función.

---

¡Listo! Con estos pasos puedes aplicar, validar con curl (y tomar tus capturas), y destruir al final para no generar costos.
