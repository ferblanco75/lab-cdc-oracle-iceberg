#!/usr/bin/env bash
# Ejecuta INSERT / UPDATE / DELETE en Oracle para ver cómo viajan por el pipeline.
set -euo pipefail
cd "$(dirname "$0")/.."
docker exec -i oracle sqlplus -s lab/lab@//localhost:1521/FREEPDB1 < sql/cambios_de_prueba.sql
