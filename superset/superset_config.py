# Superset 4.1 usa SQLAlchemy 1.4, cuyo dialecto Oracle espera el módulo cx_Oracle.
# python-oracledb (modo thin, sin Oracle Client) lo reemplaza con este alias.
import sys
import oracledb

oracledb.version = "8.3.0"
sys.modules["cx_Oracle"] = oracledb
