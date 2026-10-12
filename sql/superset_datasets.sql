-- =====================================================================
-- Datasets virtuales para Superset (SQL Lab -> pegar -> "Save dataset")
-- Base de datos: "Lakehouse Iceberg (Trino)"
-- =====================================================================

-- 1) recaudacion_mensual  (capa GOLD, ya agregada)
SELECT provincia, impuesto, mes, cantidad_pagos, total_acreditado
FROM gold.recaudacion_mensual;

-- 2) pagos_detalle  (capa SILVER, para filtros y tablas)
SELECT p.id, p.fecha_pago, p.impuesto, p.monto, p.estado,
       c.cuit, c.razon_social, c.provincia
FROM silver.pagos p
JOIN silver.clientes c ON c.id = p.cliente_id;

-- 3) salud_pipeline  (metadatos de CDC: ¿el lake está al día?)
SELECT _op AS operacion,
       COUNT(*) AS filas,
       MAX(_ts_origen) AS ultimo_cambio_en_oracle,
       MAX(_procesado_en) AS ultimo_procesado_en_lake,
       avg(date_diff('millisecond', _ts_origen, _procesado_en)) / 1000.0 AS lag_promedio_seg
FROM silver.pagos
GROUP BY _op;

-- 4) eventos_por_minuto  (capa BRONZE: actividad de CDC en el tiempo)
SELECT date_trunc('minute', ts_kafka) AS minuto,
       topico, op, COUNT(*) AS eventos
FROM bronze.cdc_eventos
GROUP BY 1, 2, 3;
