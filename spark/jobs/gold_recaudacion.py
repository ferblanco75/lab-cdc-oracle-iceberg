"""
Capa GOLD: tabla de negocio lista para BI (Superset / dashboards).
Recaudación acreditada por provincia, impuesto y mes.
"""
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("gold-recaudacion").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

spark.sql("CREATE NAMESPACE IF NOT EXISTS demo.gold")
spark.sql("""
  CREATE OR REPLACE TABLE demo.gold.recaudacion_mensual USING iceberg AS
  SELECT c.provincia,
         p.impuesto,
         date_trunc('MONTH', p.fecha_pago) AS mes,
         COUNT(*)                          AS cantidad_pagos,
         ROUND(SUM(p.monto), 2)            AS total_acreditado
  FROM demo.silver.pagos p
  JOIN demo.silver.clientes c ON c.id = p.cliente_id
  WHERE p.estado = 'ACREDITADO'
  GROUP BY c.provincia, p.impuesto, date_trunc('MONTH', p.fecha_pago)
""")
spark.sql("""SELECT provincia, ROUND(SUM(total_acreditado),2) AS total
             FROM demo.gold.recaudacion_mensual GROUP BY provincia
             ORDER BY total DESC""").show(truncate=False)
