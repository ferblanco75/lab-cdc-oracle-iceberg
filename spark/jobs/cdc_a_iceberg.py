"""
Streaming CDC: Kafka (eventos Debezium) -> Iceberg (bronze + silver)

  BRONZE  demo.bronze.cdc_eventos   -> cada evento tal cual llegó (append-only).
                                       Es el "log inmutable": permite auditoría y replay.
  SILVER  demo.silver.clientes/pagos -> estado actual de cada fila, aplicado con MERGE.
                                       Equivale a la réplica consultable de Oracle.

Conceptos que se practican:
  - Envelope de CDC: before / after / op (c=insert, u=update, d=delete, r=snapshot)
  - Orden de eventos por SCN (System Change Number de Oracle)
  - Idempotencia: si un lote se reprocesa, el MERGE no duplica filas
  - Checkpoints de Spark: retomar donde se quedó después de una caída
"""
import os
from pyspark.sql import SparkSession, functions as F, types as T
from pyspark.sql.window import Window

KAFKA = os.getenv("KAFKA_BOOTSTRAP", "kafka:9092")
CHECKPOINT = os.getenv("CHECKPOINT_DIR", "/home/iceberg/checkpoints/cdc_oracle")
TRIGGER = os.getenv("TRIGGER", "15 seconds")

spark = SparkSession.builder.appName("cdc-oracle-a-iceberg").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

# ---------------------------------------------------------------------------
# Esquemas de las filas tal como las emite Debezium (columnas en MAYÚSCULAS).
# DATE de Oracle llega como epoch en milisegundos (long).
# ---------------------------------------------------------------------------
FILA_CLIENTES = T.StructType([
    T.StructField("ID", T.LongType()),
    T.StructField("CUIT", T.StringType()),
    T.StructField("RAZON_SOCIAL", T.StringType()),
    T.StructField("PROVINCIA", T.StringType()),
    T.StructField("ACTUALIZADO_EN", T.LongType()),
])
FILA_PAGOS = T.StructType([
    T.StructField("ID", T.LongType()),
    T.StructField("CLIENTE_ID", T.LongType()),
    T.StructField("IMPUESTO", T.StringType()),
    T.StructField("MONTO", T.DoubleType()),
    T.StructField("FECHA_PAGO", T.LongType()),
    T.StructField("ESTADO", T.StringType()),
])


def envelope(fila):
    return T.StructType([
        T.StructField("before", fila),
        T.StructField("after", fila),
        T.StructField("source", T.StructType([
            T.StructField("scn", T.StringType()),
            T.StructField("ts_ms", T.LongType()),
            T.StructField("snapshot", T.StringType()),
            T.StructField("txId", T.StringType()),
        ])),
        T.StructField("op", T.StringType()),
        T.StructField("ts_ms", T.LongType()),
    ])


TABLAS = {
    "lab.LAB.CLIENTES": {
        "destino": "demo.silver.clientes",
        "schema": FILA_CLIENTES,
        "columnas": [
            "r.ID AS id",
            "r.CUIT AS cuit",
            "r.RAZON_SOCIAL AS razon_social",
            "r.PROVINCIA AS provincia",
            "timestamp_millis(r.ACTUALIZADO_EN) AS actualizado_en",
        ],
    },
    "lab.LAB.PAGOS": {
        "destino": "demo.silver.pagos",
        "schema": FILA_PAGOS,
        "columnas": [
            "r.ID AS id",
            "r.CLIENTE_ID AS cliente_id",
            "r.IMPUESTO AS impuesto",
            "r.MONTO AS monto",
            "timestamp_millis(r.FECHA_PAGO) AS fecha_pago",
            "r.ESTADO AS estado",
        ],
    },
}

PROPS_CDC = """TBLPROPERTIES (
  'format-version'='2',
  'write.delete.mode'='merge-on-read',
  'write.update.mode'='merge-on-read',
  'write.merge.mode'='merge-on-read'
)"""


def crear_tablas():
    for ns in ("bronze", "silver"):
        spark.sql(f"CREATE NAMESPACE IF NOT EXISTS demo.{ns}")

    spark.sql("""
      CREATE TABLE IF NOT EXISTS demo.bronze.cdc_eventos (
        topico        STRING,
        particion     INT,
        offset_kafka  BIGINT,
        ts_kafka      TIMESTAMP,
        clave         STRING,
        valor         STRING,
        op            STRING,
        scn           BIGINT,
        ingestado_en  TIMESTAMP
      ) USING iceberg
      PARTITIONED BY (topico, days(ingestado_en))""")

    meta = "_op STRING, _scn BIGINT, _ts_origen TIMESTAMP, _procesado_en TIMESTAMP"
    spark.sql(f"""
      CREATE TABLE IF NOT EXISTS demo.silver.clientes (
        id BIGINT, cuit STRING, razon_social STRING, provincia STRING,
        actualizado_en TIMESTAMP, {meta}
      ) USING iceberg {PROPS_CDC}""")
    spark.sql(f"""
      CREATE TABLE IF NOT EXISTS demo.silver.pagos (
        id BIGINT, cliente_id BIGINT, impuesto STRING, monto DOUBLE,
        fecha_pago TIMESTAMP, estado STRING, {meta}
      ) USING iceberg
      PARTITIONED BY (months(fecha_pago))
      {PROPS_CDC}""")


def procesar_lote(df, batch_id):
    if df.isEmpty():
        return
    sesion = df.sparkSession

    # 1) BRONZE: guardar todo, sin transformar (append-only)
    bronze = (
        df.select(
            F.col("topic").alias("topico"),
            F.col("partition").alias("particion"),
            F.col("offset").alias("offset_kafka"),
            F.col("timestamp").alias("ts_kafka"),
            F.col("key").cast("string").alias("clave"),
            F.col("value").cast("string").alias("valor"),
        )
        .withColumn("op", F.get_json_object("valor", "$.op"))
        .withColumn("scn", F.get_json_object("valor", "$.source.scn").cast("bigint"))
        .withColumn("ingestado_en", F.current_timestamp())
        .persist()
    )
    bronze.writeTo("demo.bronze.cdc_eventos").append()

    # 2) SILVER: aplicar cambios por tabla con MERGE
    for topico, cfg in TABLAS.items():
        eventos = bronze.filter((F.col("topico") == topico) & F.col("valor").isNotNull())
        if eventos.isEmpty():
            continue

        e = eventos.withColumn("e", F.from_json("valor", envelope(cfg["schema"])))
        # En un DELETE la fila viene en "before"; en el resto, en "after"
        e = e.withColumn("r", F.when(F.col("e.op") == "d", F.col("e.before"))
                               .otherwise(F.col("e.after")))
        cambios = e.selectExpr(
            *cfg["columnas"],
            "e.op AS _op",
            "CAST(e.source.scn AS BIGINT) AS _scn",
            "timestamp_millis(e.ts_ms) AS _ts_origen",
            "current_timestamp() AS _procesado_en",
            "offset_kafka",
        )

        # Si en el mismo lote hay varios cambios de una fila, nos quedamos con el último
        w = Window.partitionBy("id").orderBy(F.col("_scn").desc(), F.col("offset_kafka").desc())
        ultimos = (cambios.withColumn("_rn", F.row_number().over(w))
                          .filter("_rn = 1").drop("_rn", "offset_kafka"))

        vista = "cambios_" + cfg["destino"].split(".")[-1]
        ultimos.createOrReplaceTempView(vista)
        sesion.sql(f"""
          MERGE INTO {cfg['destino']} t
          USING {vista} s
          ON t.id = s.id
          WHEN MATCHED AND s._op = 'd'            THEN DELETE
          WHEN MATCHED AND s._scn >= t._scn       THEN UPDATE SET *
          WHEN NOT MATCHED AND s._op <> 'd'       THEN INSERT *
        """)

    resumen = bronze.groupBy("topico", "op").count().collect()
    print(f"[lote {batch_id}] " + ", ".join(f"{r.topico}:{r.op}={r['count']}" for r in resumen),
          flush=True)
    bronze.unpersist()


if __name__ == "__main__":
    crear_tablas()
    flujo = (
        spark.readStream.format("kafka")
        .option("kafka.bootstrap.servers", KAFKA)
        .option("subscribe", ",".join(TABLAS.keys()))
        .option("startingOffsets", "earliest")
        .option("failOnDataLoss", "false")
        .load()
    )
    consulta = (
        flujo.writeStream
        .foreachBatch(procesar_lote)
        .option("checkpointLocation", CHECKPOINT)
        .trigger(processingTime=TRIGGER)
        .start()
    )
    print(">>> Streaming CDC iniciado. Ctrl+C para detener.", flush=True)
    consulta.awaitTermination()
