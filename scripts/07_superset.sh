#!/usr/bin/env bash
# Levanta Superset (~1,5 GB de RAM). Para el lakehouse necesita Trino; para el plan de estudio, solo Oracle.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up -d --build superset
echo "Esperando a Superset (la primera vez tarda 1-2 min)..."
until curl -sf http://localhost:8088/health >/dev/null; do sleep 5; done
echo "Listo: http://localhost:8088  (usuario admin / clave admin)"
