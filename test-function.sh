#!/bin/bash
# Script para probar la Azure Function desplegada
# Uso: ./test-function.sh

set -e

echo "======================================"
echo "Probando Azure Function"
echo "======================================"
echo ""

# Verificar que Terraform esté inicializado
if [ ! -d ".terraform" ]; then
    echo "❌ Error: Terraform no está inicializado en este directorio."
    echo "   Ejecuta 'terraform init' primero."
    exit 1
fi

# Verificar que exista el estado de Terraform
if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: No se encuentra terraform.tfstate"
    echo "   Debes ejecutar 'terraform apply' primero para desplegar la infraestructura."
    exit 1
fi

# Obtener la URL de la función
echo "📡 Obteniendo URL de la función..."
FUNCTION_URL=$(terraform output -raw function_invocation_url 2>/dev/null)

if [ -z "$FUNCTION_URL" ]; then
    echo "❌ Error: No se pudo obtener la URL de la función."
    echo "   Verifica que la infraestructura esté desplegada correctamente."
    exit 1
fi

echo "✅ URL obtenida: $FUNCTION_URL"
echo ""

# Prueba 1: Sin parámetros
echo "======================================"
echo "Prueba 1: Petición sin parámetros"
echo "======================================"
echo "Comando: curl -s \"$FUNCTION_URL\""
echo ""
echo "Respuesta:"
curl -s "$FUNCTION_URL"
echo ""
echo ""

# Prueba 2: Con parámetro en query string
echo "======================================"
echo "Prueba 2: Petición GET con query string"
echo "======================================"
echo "Comando: curl -s \"${FUNCTION_URL}&name=Terraform\""
echo ""
echo "Respuesta:"
curl -s "${FUNCTION_URL}&name=Terraform" | jq '.' 2>/dev/null || curl -s "${FUNCTION_URL}&name=Terraform"
echo ""
echo ""

# Prueba 3: POST con body JSON
echo "======================================"
echo "Prueba 3: Petición POST con body JSON"
echo "======================================"
echo "Comando: curl -X POST -H \"Content-Type: application/json\" -d '{\"name\":\"DevOps\"}' \"$FUNCTION_URL\""
echo ""
echo "Respuesta:"
curl -s -X POST -H "Content-Type: application/json" -d '{"name":"DevOps"}' "$FUNCTION_URL" | jq '.' 2>/dev/null || curl -s -X POST -H "Content-Type: application/json" -d '{"name":"DevOps"}' "$FUNCTION_URL"
echo ""
echo ""

# Resumen
echo "======================================"
echo "✅ Todas las pruebas completadas"
echo "======================================"
echo ""
echo "Información adicional:"
echo "  - Resource Group: $(terraform output -raw resource_group_name)"
echo "  - Function App: $(terraform output -raw function_app_name)"
echo ""
echo "Para ver logs en tiempo real, ejecuta:"
echo "  az webapp log tail --name \$(terraform output -raw function_app_name) \\"
echo "    --resource-group \$(terraform output -raw resource_group_name)"
