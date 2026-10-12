-- Cambios de prueba sobre el esquema LAB (ejecutar como usuario lab)
SET SERVEROUTPUT ON FEEDBACK ON

-- 1) INSERT: un contribuyente nuevo con dos pagos
INSERT INTO clientes (cuit, razon_social, provincia)
VALUES ('30-71234567-9', 'Cooperativa de Prueba Ltda', 'Buenos Aires');

INSERT INTO pagos (cliente_id, impuesto, monto, fecha_pago, estado)
SELECT MAX(id), 'IVA', 125000.50, TRUNC(SYSDATE), 'PENDIENTE' FROM clientes;
INSERT INTO pagos (cliente_id, impuesto, monto, fecha_pago, estado)
SELECT MAX(id), 'GANANCIAS', 98000.00, TRUNC(SYSDATE), 'ACREDITADO' FROM clientes;

-- 2) UPDATE: el contribuyente 1 se muda de provincia
UPDATE clientes SET provincia = 'Neuquen', actualizado_en = SYSDATE WHERE id = 1;

-- 3) UPDATE masivo: se acreditan los pagos pendientes de hace más de 30 días
UPDATE pagos SET estado = 'ACREDITADO'
WHERE estado = 'PENDIENTE' AND fecha_pago < TRUNC(SYSDATE) - 30;

-- 4) DELETE: se anulan pagos rechazados de un cliente
DELETE FROM pagos WHERE estado = 'RECHAZADO' AND cliente_id = 2;

COMMIT;

-- 5) Carga continua: 200 pagos nuevos en 4 transacciones
BEGIN
  FOR t IN 1..4 LOOP
    FOR i IN 1..50 LOOP
      INSERT INTO pagos (cliente_id, impuesto, monto, fecha_pago, estado)
      VALUES (TRUNC(DBMS_RANDOM.VALUE(1, 51)), 'MONOTRIBUTO',
              ROUND(DBMS_RANDOM.VALUE(5000, 60000), 2), TRUNC(SYSDATE), 'ACREDITADO');
    END LOOP;
    COMMIT;
    DBMS_SESSION.SLEEP(2);
  END LOOP;
END;
/
SELECT 'Cambios aplicados. pagos=' || COUNT(*) AS resultado FROM pagos;
EXIT
