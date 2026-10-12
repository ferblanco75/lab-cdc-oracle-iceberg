"""
Mantenimiento de tablas Iceberg. Con CDC continuo se generan muchos archivos
chicos y archivos de borrado (merge-on-read). Sin mantenimiento, las consultas
se degradan con el tiempo. En producción esto se agenda con Airflow.
"""
from datetime import datetime, timedelta
from pyspark.sql import SparkSession

spark = SparkSession.builder.appName("mantenimiento-iceberg").getOrCreate()
spark.sparkContext.setLogLevel("WARN")

limite = (datetime.utcnow() - timedelta(minutes=10)).strftime("%Y-%m-%d %H:%M:%S")

for tabla in ("silver.clientes", "silver.pagos"):
    print(f"\n=== {tabla} ===")
    print("Archivos antes:")
    spark.sql(f"SELECT content, COUNT(*) AS archivos FROM demo.{tabla}.files GROUP BY content").show()

    # 1) Compactar archivos de datos chicos y aplicar los deletes pendientes
    spark.sql(f"""CALL demo.system.rewrite_data_files(
                    table => '{tabla}',
                    options => map('min-input-files','2','delete-file-threshold','1'))""").show()
    # 2) Expirar snapshots viejos (libera espacio; limita el time travel)
    spark.sql(f"""CALL demo.system.expire_snapshots(
                    table => '{tabla}',
                    older_than => TIMESTAMP '{limite}',
                    retain_last => 5)""").show()

    print("Archivos después:")
    spark.sql(f"SELECT content, COUNT(*) AS archivos FROM demo.{tabla}.files GROUP BY content").show()
