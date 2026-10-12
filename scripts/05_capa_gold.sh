#!/usr/bin/env bash
set -euo pipefail
docker exec -it spark-iceberg spark-submit /home/iceberg/jobs/gold_recaudacion.py
