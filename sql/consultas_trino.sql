-- Consultas para la consola de Trino (scripts/trino.sh)

SHOW SCHEMAS;
SHOW TABLES FROM silver;

-- Estado actual replicado
SELECT * FROM silver.clientes ORDER BY id LIMIT 10;

-- El cliente 1 ¿cambió de provincia?
SELECT id, provincia, _op, _scn, _ts_origen FROM silver.clientes WHERE id = 1;

-- Latencia aproximada: cuánto tardó cada cambio en llegar al lake
SELECT _op,
       COUNT(*) AS filas,
       avg(date_diff('millisecond', _ts_origen, _procesado_en)) / 1000.0 AS lag_promedio_seg
FROM silver.pagos GROUP BY _op;

-- Historia completa de una fila desde BRONZE (auditoría temporal)
SELECT ts_kafka, op, scn,
       json_extract_scalar(valor, '$.before.ESTADO') AS estado_antes,
       json_extract_scalar(valor, '$.after.ESTADO')  AS estado_despues
FROM bronze.cdc_eventos
WHERE topico = 'lab.LAB.PAGOS'
  AND (json_extract_scalar(valor, '$.after.ID') = '10'
       OR json_extract_scalar(valor, '$.before.ID') = '10')
ORDER BY scn;

-- Snapshots de Iceberg (cada lote de Spark genera uno)
SELECT committed_at, snapshot_id, operation, summary['added-records'] AS agregados
FROM silver."pagos$snapshots" ORDER BY committed_at DESC;

-- Time travel: ¿cómo estaba la tabla hace 5 minutos?
SELECT COUNT(*) FROM silver.pagos FOR TIMESTAMP AS OF (current_timestamp - INTERVAL '5' MINUTE);

-- Archivos físicos (para entender la compactación)
SELECT content, COUNT(*) AS archivos, SUM(record_count) AS registros
FROM silver."pagos$files" GROUP BY content;

-- Capa GOLD (después de correr scripts/05_capa_gold.sh)
SELECT * FROM gold.recaudacion_mensual ORDER BY total_acreditado DESC LIMIT 20;
