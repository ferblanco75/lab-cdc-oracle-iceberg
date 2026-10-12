#!/bin/bash
# ---------------------------------------------------------------
# Prepara Oracle para CDC con LogMiner (lo mismo que necesita
# GoldenGate en producción, conceptualmente):
#   1. ARCHIVELOG: los redo logs se archivan en lugar de pisarse.
#   2. Supplemental logging: los redo guardan datos extra para
#      reconstruir cada fila cambiada.
#   3. Usuario común c##dbzuser con permisos de LogMiner.
# Se ejecuta UNA sola vez, al crear la base.
# ---------------------------------------------------------------
echo ">>> [lab] Habilitando ARCHIVELOG y supplemental logging..."
mkdir -p /opt/oracle/oradata/recovery_area

sqlplus -s / as sysdba <<'SQL'
ALTER SYSTEM SET db_recovery_file_dest_size = 10G;
ALTER SYSTEM SET db_recovery_file_dest = '/opt/oracle/oradata/recovery_area' SCOPE=SPFILE;
ALTER SYSTEM SET db_create_file_dest = '/opt/oracle/oradata' SCOPE=BOTH;
SHUTDOWN IMMEDIATE
STARTUP MOUNT
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;
ALTER PLUGGABLE DATABASE ALL OPEN;
ALTER PLUGGABLE DATABASE ALL SAVE STATE;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;
ARCHIVE LOG LIST
SQL

echo ">>> [lab] Creando usuario de captura c##dbzuser..."
sqlplus -s / as sysdba <<'SQL'
CREATE TABLESPACE logminer_tbs DATAFILE SIZE 25M AUTOEXTEND ON MAXSIZE UNLIMITED;
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE TABLESPACE logminer_tbs DATAFILE SIZE 25M AUTOEXTEND ON MAXSIZE UNLIMITED;
ALTER SESSION SET CONTAINER = CDB$ROOT;

CREATE USER c##dbzuser IDENTIFIED BY dbz
  DEFAULT TABLESPACE logminer_tbs
  QUOTA UNLIMITED ON logminer_tbs
  CONTAINER = ALL;

GRANT CREATE SESSION              TO c##dbzuser CONTAINER = ALL;
GRANT SET CONTAINER               TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$DATABASE       TO c##dbzuser CONTAINER = ALL;
GRANT FLASHBACK ANY TABLE         TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ANY TABLE            TO c##dbzuser CONTAINER = ALL;
GRANT SELECT_CATALOG_ROLE         TO c##dbzuser CONTAINER = ALL;
GRANT EXECUTE_CATALOG_ROLE        TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ANY TRANSACTION      TO c##dbzuser CONTAINER = ALL;
GRANT LOGMINING                   TO c##dbzuser CONTAINER = ALL;
GRANT CREATE TABLE                TO c##dbzuser CONTAINER = ALL;
GRANT LOCK ANY TABLE              TO c##dbzuser CONTAINER = ALL;
GRANT CREATE SEQUENCE             TO c##dbzuser CONTAINER = ALL;
GRANT EXECUTE ON DBMS_LOGMNR      TO c##dbzuser CONTAINER = ALL;
GRANT EXECUTE ON DBMS_LOGMNR_D    TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$LOG                 TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$LOG_HISTORY         TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$LOGMNR_LOGS         TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$LOGMNR_CONTENTS     TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$LOGMNR_PARAMETERS   TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$LOGFILE             TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$ARCHIVED_LOG        TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$ARCHIVE_DEST_STATUS TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$TRANSACTION         TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$MYSTAT              TO c##dbzuser CONTAINER = ALL;
GRANT SELECT ON V_$STATNAME            TO c##dbzuser CONTAINER = ALL;
SQL
echo ">>> [lab] CDC habilitado."
