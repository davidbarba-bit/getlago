#!/bin/bash
set -e

echo "=== Lago Self-Hosted Setup ==="
echo ""

# Verificar dependencias
command -v docker >/dev/null 2>&1 || { echo "ERROR: Docker no está instalado."; exit 1; }
command -v openssl >/dev/null 2>&1 || { echo "ERROR: openssl no está instalado."; exit 1; }

ENV_FILE=".env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: No se encontró el archivo .env. Copia .env.example y configúralo."
  exit 1
fi

# Generar SECRET_KEY_BASE si no está definido
if grep -q "^SECRET_KEY_BASE=$" "$ENV_FILE" || ! grep -q "^SECRET_KEY_BASE=" "$ENV_FILE"; then
  SECRET=$(openssl rand -hex 64)
  if grep -q "^SECRET_KEY_BASE=" "$ENV_FILE"; then
    sed -i "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=${SECRET}|" "$ENV_FILE"
  else
    echo "SECRET_KEY_BASE=${SECRET}" >> "$ENV_FILE"
  fi
  echo "✓ SECRET_KEY_BASE generado"
fi

# Generar claves de encriptación si no están definidas
generate_if_empty() {
  local key=$1
  local val
  val=$(openssl rand -hex 16)
  if grep -q "^${key}=$" "$ENV_FILE"; then
    sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
    echo "✓ ${key} generado"
  fi
}

generate_if_empty "ENCRYPTION_PRIMARY_KEY"
generate_if_empty "ENCRYPTION_DETERMINISTIC_KEY"
generate_if_empty "ENCRYPTION_KEY_DERIVATION_SALT"

# Generar RSA key si no está definida
if grep -q "^LAGO_RSA_PRIVATE_KEY=$" "$ENV_FILE"; then
  RSA_KEY=$(openssl genrsa 2048 2>/dev/null | base64 | tr -d '\n')
  sed -i "s|^LAGO_RSA_PRIVATE_KEY=.*|LAGO_RSA_PRIVATE_KEY=${RSA_KEY}|" "$ENV_FILE"
  echo "✓ LAGO_RSA_PRIVATE_KEY generado"
fi

echo ""
echo "Iniciando servicios con Docker Compose..."
docker compose up -d

echo ""
echo "Esperando a que la base de datos esté lista..."
sleep 10

echo ""
echo "Ejecutando migraciones de base de datos..."
docker compose exec api bundle exec rails db:migrate

echo ""
echo "=== Instalación completada ==="
echo ""
echo "Frontend: http://localhost"
echo "API:      http://localhost:3000"
echo ""
echo "Crea tu cuenta en http://localhost para comenzar."
