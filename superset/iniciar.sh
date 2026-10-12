#!/bin/bash
# Inicializa Superset la primera vez y registra las conexiones.
set -e
superset db upgrade
superset fab create-admin --username admin --firstname Admin --lastname Lab \
  --email admin@lab.local --password admin || true
superset init
# Conexión al lakehouse (Trino -> Iceberg). Funciona cuando Trino está arriba.
superset set-database-uri -d "Lakehouse Iceberg (Trino)" -u "trino://superset@trino:8080/iceberg" || true
# Conexión directa a Oracle con el usuario de práctica del plan de estudio.
superset set-database-uri -d "Oracle FREEPDB1 (practica)" -u "oracle://practica:practica@oracle:1521/?service_name=FREEPDB1" || true
exec /usr/bin/run-server.sh
