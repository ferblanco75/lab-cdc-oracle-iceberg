#!/usr/bin/env bash
# Registra el conector Debezium para Oracle (equivale a crear el Extract de GoldenGate).
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Esperando a Kafka Connect..."
until curl -sf http://localhost:8083/connector-plugins >/dev/null; do sleep 3; done
curl -s http://localhost:8083/connector-plugins | grep -q OracleConnector \
  && echo "Plugin OracleConnector disponible." \
  || { echo "ERROR: no se encontró el plugin de Oracle"; exit 1; }

curl -s -X POST -H "Content-Type: application/json" \
     --data @debezium/oracle-connector.json \
     http://localhost:8083/connectors | sed 's/,/,\n/g' | head -5
echo
sleep 5
echo "Estado del conector:"
curl -s http://localhost:8083/connectors/oracle-lab/status
echo
