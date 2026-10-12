# Laboratorio CDC: Oracle → Kafka → Iceberg

Réplica en miniatura de la arquitectura propuesta (Oracle + GoldenGate + Kafka + HPE Data Fabric),
con herramientas open source que corren en una notebook.

| Rol en la propuesta            | En este laboratorio                    | URL / puerto            |
|--------------------------------|----------------------------------------|-------------------------|
| Oracle Exadata (OLTP)          | Oracle Database Free 23ai              | localhost:1521          |
| GoldenGate for Big Data        | Debezium (Kafka Connect, LogMiner)     | http://localhost:8083   |
| Kafka                          | Apache Kafka 3.9 (KRaft)               | localhost:29092         |
| (monitoreo de streams)         | Kafka UI                               | http://localhost:8081   |
| Data Fabric Object Store       | RustFS (compatible S3)                 | http://localhost:9001   |
| Data Lakehouse Gateway         | Iceberg REST Catalog                   | http://localhost:8181   |
| Spark                          | Spark + Iceberg (+ Jupyter)            | http://localhost:8888   |
| Presto                         | Trino                                  | http://localhost:8085   |
| Superset (BI)                  | Apache Superset 4.1                    | http://localhost:8088   |

## Requisitos
- Docker Desktop (o Docker Engine + Compose v2) con **12–16 GB de RAM** asignados.
- ~20 GB libres de disco. Funciona en Linux, Windows (WSL2) y Mac (Intel o Apple Silicon).

## Arranque rápido
```bash
docker compose up -d --build
docker logs -f oracle          # esperar "DATABASE IS READY TO USE!" (5-10 min la 1ra vez)
./scripts/00_verificar_oracle.sh
./scripts/01_registrar_conector.sh
./scripts/02_iniciar_streaming.sh      # en otra terminal; dejarla abierta
./scripts/03_generar_cambios.sh
./scripts/04_reconciliar.sh
./scripts/05_capa_gold.sh
./scripts/trino.sh                     # consultas en sql/consultas_trino.sql
./scripts/07_superset.sh               # dashboards (datasets en sql/superset_datasets.sql)
```

## Reiniciar de cero
```bash
docker compose down -v    # borra volúmenes: Oracle, lake y checkpoints
```

La guía completa paso a paso está en el PDF que acompaña este laboratorio.

## Plan de estudio (SQL, Oracle y Superset)
La carpeta `estudio/` acompaña el PDF *Plan de 1 mes*:
- `00_usuario_practica.sql`: crea el usuario `practica` (día 0).
- `catalogo.py`: mini catálogo de datos desde el diccionario de Oracle (semana 3).

Para el plan alcanza con levantar `oracle` (semanas 1 a 3) y `oracle` + `superset` (semana 4).
Superset ya trae registrada la conexión "Oracle FREEPDB1 (practica)".
