# Apache Superset + drivers de Trino (lakehouse) y Oracle (práctica directa)
FROM apache/superset:4.1.1
USER root
RUN pip install --no-cache-dir "trino[sqlalchemy]" oracledb
USER superset
