#!/usr/bin/env bash
# Reconciliación origen vs lake: conteos y sumas de control.
# En el proyecto real esto se automatiza y se reporta por tabla y por ventana de tiempo.
set -euo pipefail
echo "================ ORACLE (origen) ================"
docker exec -i oracle sqlplus -s lab/lab@//localhost:1521/FREEPDB1 <<'SQL'
SET HEADING OFF FEEDBACK OFF PAGESIZE 0
SELECT 'clientes  filas=' || COUNT(*) FROM clientes;
SELECT 'pagos     filas=' || COUNT(*) || '  suma_monto=' || TO_CHAR(SUM(monto), 'FM999999999990.00') FROM pagos;
SELECT 'pagos ACREDITADO=' || COUNT(*) FROM pagos WHERE estado = 'ACREDITADO';
SQL
echo "================ LAKE (Iceberg vía Trino) ================"
docker exec trino trino --output-format TSV --execute "
SELECT 'clientes  filas=' || CAST(COUNT(*) AS varchar) FROM iceberg.silver.clientes;
SELECT 'pagos     filas=' || CAST(COUNT(*) AS varchar) || '  suma_monto=' || format('%.2f', SUM(monto)) FROM iceberg.silver.pagos;
SELECT 'pagos ACREDITADO=' || CAST(COUNT(*) AS varchar) FROM iceberg.silver.pagos WHERE estado = 'ACREDITADO';
"
echo
echo "Si los números coinciden, la réplica está consistente (con el lag del último lote)."
