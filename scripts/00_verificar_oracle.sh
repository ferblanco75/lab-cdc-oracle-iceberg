#!/usr/bin/env bash
# Verifica que Oracle quedó listo para CDC.
set -euo pipefail
docker exec -i oracle sqlplus -s / as sysdba <<'SQL'
SET LINESIZE 120 PAGESIZE 50
PROMPT === Modo de log (debe decir ARCHIVELOG) ===
SELECT log_mode, supplemental_log_data_min AS supl_min FROM v$database;
PROMPT === PDBs abiertas ===
SELECT name, open_mode FROM v$pdbs;
ALTER SESSION SET CONTAINER = FREEPDB1;
PROMPT === Tablas del esquema LAB ===
SELECT table_name, num_rows FROM all_tables WHERE owner = 'LAB';
SELECT 'clientes=' || COUNT(*) AS conteo FROM lab.clientes
UNION ALL SELECT 'pagos=' || COUNT(*) FROM lab.pagos;
SQL
