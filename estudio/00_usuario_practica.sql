-- Usuario de trabajo para el plan de estudio (ejecutar como SYSTEM en FREEPDB1):
--   docker exec -i oracle sqlplus system/oracle@//localhost/FREEPDB1 < estudio/00_usuario_practica.sql
CREATE USER practica IDENTIFIED BY practica
  DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE TO practica;
-- Lectura de los esquemas de ejemplo (HR, SH) y de las vistas del sistema
GRANT SELECT ANY TABLE      TO practica;
GRANT SELECT ANY DICTIONARY TO practica;
-- Para analizar planes de ejecución reales (semana 3)
GRANT ALTER SESSION TO practica;
SELECT 'Usuario practica listo' AS resultado FROM dual;
EXIT
