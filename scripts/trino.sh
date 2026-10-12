#!/usr/bin/env bash
# Abre la consola SQL de Trino apuntando al catálogo Iceberg.
docker exec -it trino trino --catalog iceberg
