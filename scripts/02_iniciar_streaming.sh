#!/usr/bin/env bash
# Lanza el job de Spark Structured Streaming (Kafka -> Iceberg).
# Dejá esta terminal abierta: vas a ver un resumen por cada lote procesado.
set -euo pipefail
docker exec -it spark-iceberg bash -c '
  SPARK_HOME=${SPARK_HOME:-/opt/spark}
  JAR=$(ls $SPARK_HOME/jars/spark-core_*.jar | head -n1)
  BASE=$(basename "$JAR" .jar)
  SCALA=$(echo "$BASE" | sed -E "s/^spark-core_([0-9.]+)-.*/\1/")
  SPARK_V=$(echo "$BASE" | sed -E "s/^spark-core_[0-9.]+-//")
  echo ">>> Spark $SPARK_V (Scala $SCALA)"
  spark-submit \
    --packages org.apache.spark:spark-sql-kafka-0-10_${SCALA}:${SPARK_V} \
    /home/iceberg/jobs/cdc_a_iceberg.py
'
