SELECT table_name FROM all_tables WHERE owner = 'HR' ORDER BY table_name;
SELECT * FROM hr.employees FETCH FIRST 5 ROWS ONLY;

SELECT e.employee_id, e.last_name, d.department_name
FROM hr.employees e
         JOIN hr.departments d ON d.department_id = e.department_id;


SELECT employee_id, first_name, last_name, manager_id, department_id
FROM hr.employees
WHERE manager_id IS NULL OR department_id IS NULL;

SELECT e.employee_id, e.last_name
FROM hr.employees e
         LEFT JOIN hr.departments d ON d.department_id = e.department_id
WHERE d.department_id IS NULL;

-- Paso 2: empleados con su departamento (INNER JOIN)
SELECT e.employee_id, e.last_name, d.department_name
FROM hr.employees e
         JOIN hr.departments d ON d.department_id = e.department_id;

-- Paso 5: huérfanos de ambos lados (FULL JOIN)
SELECT e.last_name, d.department_name
FROM hr.employees e
         FULL JOIN hr.departments d ON d.department_id = e.department_id
WHERE e.employee_id IS NULL OR d.department_id IS NULL;


-- Paso 4: departamentos sin empleados
SELECT d.department_id, d.department_name
FROM hr.departments d
         LEFT JOIN hr.employees e ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;

SELECT d.department_id, d.department_name, loc.city
FROM hr.departments d
         JOIN hr.locations loc ON loc.location_id = d.location_id;

SELECT d.department_id, d.department_name , COUNT(location_id) as locaciones
FROM hr.departments d  JOIN hr.LOCATIONS loc ON  d.LOCATION_ID = loc.LOCATION_ID  GROUP BY d.department_id, d.department_name;

SELECT d.department_id,
       d.department_name,
       loc.city,
       COUNT(e.employee_id) AS empleados
FROM hr.departments d
         JOIN hr.locations loc ON loc.location_id = d.location_id
         LEFT JOIN hr.employees e ON d.DEPARTMENT_ID = e.DEPARTMENT_ID
GROUP BY d.department_id,
      d.department_name,
      loc.city
ORDER BY empleados DESC;

SELECT * FROM sh.sales FETCH FIRST 5 ROWS ONLY;

SELECT * FROM sh.channels;

-- Paso 2: ventas y unidades por canal
SELECT c.channel_desc,
       ROUND(SUM(s.amount_sold)) AS ventas,
       SUM(s.quantity_sold)      AS unidades
FROM sh.sales s
         JOIN sh.channels c ON c.channel_id = s.channel_id
GROUP BY c.channel_desc
ORDER BY ventas DESC;


SELECT c.channel_desc,
       ROUND(SUM(s.amount_sold)) AS ventas,
       SUM(s.quantity_sold)      AS unidades
FROM sh.sales s
         JOIN sh.channels c ON c.channel_id = s.channel_id
GROUP BY c.channel_desc
ORDER BY ventas DESC;

-- Paso 2b: todos los canales, incluido el que no vendió
SELECT c.channel_desc,
       ROUND(NVL(SUM(s.amount_sold), 0)) AS ventas,
       COUNT(s.channel_id)               AS cantidad_ventas
FROM sh.channels c
         LEFT JOIN sh.sales s ON s.channel_id = c.channel_id
GROUP BY c.channel_desc
ORDER BY ventas DESC;

SELECT t.calendar_year,
       c.channel_desc,
       ROUND(SUM(s.amount_sold)) AS ventas
FROM sh.sales s
         JOIN sh.times    t ON t.time_id    = s.time_id
         JOIN sh.channels c ON c.channel_id = s.channel_id
GROUP BY t.calendar_year, c.channel_desc
ORDER BY t.calendar_year, ventas DESC;


-- Paso 3b: total por año (sin el canal)
SELECT t.calendar_year,
       ROUND(SUM(s.amount_sold)) AS ventas,
       COUNT(*)                  AS cantidad_ventas
FROM sh.sales s
         JOIN sh.times t ON t.time_id = s.time_id
GROUP BY t.calendar_year
ORDER BY t.calendar_year;



-- Ejercicio Día 2: ventas por región y año, regiones de más de 5 millones
SELECT co.country_region,
       ROUND(SUM(CASE WHEN t.calendar_year = 2019 THEN s.amount_sold END)) AS v2019,
       ROUND(SUM(CASE WHEN t.calendar_year = 2020 THEN s.amount_sold END)) AS v2020,
       ROUND(SUM(CASE WHEN t.calendar_year = 2021 THEN s.amount_sold END)) AS v2021,
       ROUND(SUM(CASE WHEN t.calendar_year = 2022 THEN s.amount_sold END)) AS v2022,
       ROUND(SUM(s.amount_sold)) AS total
FROM sh.sales s
         JOIN sh.times t      ON s.TIME_ID = t.TIME_ID
         JOIN sh.customers cu ON s.CUST_ID = cu.CUST_ID
         JOIN sh.countries co ON cu.COUNTRY_ID = co.COUNTRY_ID
GROUP BY co.country_region
HAVING  SUM(s.amount_sold) > 5000000
ORDER BY total DESC;


-- =========================================================
-- Semana 1 · Día 3 · Subconsultas y EXISTS
-- =========================================================

-- Paso 1: empleados que ganan más que el promedio general
SELECT last_name, salary
FROM hr.employees
WHERE salary > (SELECT AVG(salary) FROM hr.employees)
ORDER BY salary DESC;

SELECT AVG(salary) FROM hr.employees;


SELECT e.last_name, e.department_id, e.salary
FROM hr.employees e
WHERE e.salary > (SELECT AVG(x.salary)
                  FROM hr.employees x
                  WHERE x.department_id = e.department_id)
ORDER BY e.department_id, e.salary DESC;

-- Paso 3: clientes con al menos una compra en 2022
SELECT COUNT(*)
FROM sh.customers c
WHERE EXISTS (SELECT 1
              FROM sh.sales s
              WHERE s.cust_id = c.cust_id
                AND s.time_id >= DATE '2022-01-01'
                AND s.time_id <  DATE '2023-01-01');

-- Paso 3: clientes con al menos una compra en 2022
SELECT COUNT(*)
FROM sh.customers c
WHERE EXISTS (SELECT 1
              FROM sh.sales s
              WHERE s.cust_id = c.cust_id
                AND s.time_id >= DATE '2022-01-01'
                AND s.time_id <  DATE '2023-01-01');
SELECT COUNT(*)
FROM sh.customers c
WHERE EXISTS     (SELECT 1 FROM sh.sales s
                  WHERE s.cust_id = c.cust_id
                    AND s.time_id >= DATE '2021-01-01' AND s.time_id < DATE '2022-01-01')
  AND NOT EXISTS (SELECT 1 FROM sh.sales s
                  WHERE s.cust_id = c.cust_id
                    AND s.time_id >= DATE '2022-01-01' AND s.time_id < DATE '2023-01-01');


-- Paso 4b: compradores por año y clientes que repiten
SELECT COUNT(CASE WHEN c2021 > 0 THEN 1 END)                AS compradores_2021,
       COUNT(CASE WHEN c2022 > 0 THEN 1 END)                AS compradores_2022,
       COUNT(CASE WHEN c2021 > 0 AND c2022 > 0 THEN 1 END)  AS en_ambos_anios,
       COUNT(CASE WHEN c2021 > 0 AND c2022 = 0 THEN 1 END)  AS perdidos,
       COUNT(CASE WHEN c2021 = 0 AND c2022 > 0 THEN 1 END)  AS nuevos_o_recuperados
FROM (
         SELECT cust_id,
                COUNT(CASE WHEN time_id >= DATE '2021-01-01' AND time_id < DATE '2022-01-01' THEN 1 END) AS c2021,
                COUNT(CASE WHEN time_id >= DATE '2022-01-01' AND time_id < DATE '2023-01-01' THEN 1 END) AS c2022
         FROM sh.sales
         GROUP BY cust_id
     );

-- Paso 5a: departamentos sin empleados con NOT IN
SELECT department_name
FROM hr.departments
WHERE department_id NOT IN (SELECT department_id FROM hr.employees);


SELECT d.department_name
FROM hr.departments d
WHERE NOT EXISTS (SELECT 1 FROM hr.employees e
                  WHERE e.department_id = d.department_id);


--El orden en que Oracle procesa la consulta lo explica todo:
-- FROM / JOIN  →  WHERE  →  GROUP BY  →  HAVING  →  SELECT  →  ORDER BY

-- Paso 6: gasto promedio por cliente (dos niveles de agregación)
SELECT ROUND(AVG(total)) AS gasto_promedio_por_cliente
FROM (SELECT cust_id, SUM(amount_sold) AS total
      FROM sh.sales
      GROUP BY cust_id);
-- ¿Qué mide esta?
SELECT ROUND(AVG(amount_sold)) AS promedio
FROM sh.sales;


--sql
-- Ejercicio Día 3: productos nunca vendidos por Internet
SELECT p.prod_id, p.prod_name, p.prod_category
FROM sh.products p
WHERE NOT EXISTS (
    SELECT 1
    FROM sh.sales s
             JOIN sh.channels c ON s.CHANNEL_ID = c.CHANNEL_ID
    WHERE s.prod_id = p.PROD_ID
      AND c.channel_desc = 'Tele Sales'
)
ORDER BY p.prod_category, p.prod_name;

SELECT c.channel_desc,
       COUNT(DISTINCT s.prod_id) AS productos_vendidos
FROM sh.sales s
         JOIN sh.channels c ON c.channel_id = s.channel_id
GROUP BY c.channel_desc
ORDER BY productos_vendidos;

-- =========================================================
-- Semana 1 · Día 4 · CTEs
-- =========================================================

sql
-- Paso 1: clientes perdidos con CTEs
WITH clientes_2021 AS (
    SELECT DISTINCT cust_id
    FROM sh.sales
    WHERE time_id >= DATE '2021-01-01' AND time_id < DATE '2022-01-01'
),
     clientes_2022 AS (
         SELECT DISTINCT cust_id
         FROM sh.sales
         WHERE time_id >= DATE '2022-01-01' AND time_id < DATE '2023-01-01'
     )
SELECT COUNT(*)
FROM clientes_2021 a
WHERE EXISTS (SELECT 1 FROM clientes_2022 b WHERE b.cust_id = a.cust_id);


WITH ventas_cliente AS (
    SELECT cust_id, SUM(amount_sold) AS total
    FROM sh.sales
    GROUP BY cust_id
)
SELECT COUNT(*) AS clientes, ROUND(SUM(total)) AS ventas
FROM ventas_cliente;


WITH ventas_cliente AS (
    SELECT cust_id, SUM(amount_sold) AS total
    FROM sh.sales
    GROUP BY cust_id
),
     segmentado AS (
         SELECT cust_id, total,
                CASE WHEN total >= 10000 THEN '1-Alto'
                     WHEN total >=  2000 THEN '2-Medio'
                     ELSE '3-Bajo' END AS segmento
         FROM ventas_cliente
     )
SELECT segmento, COUNT(*) AS clientes
FROM segmentado
GROUP BY segmento
ORDER BY segmento;


WITH ventas_cliente AS (
    SELECT cust_id, SUM(amount_sold) AS total
    FROM sh.sales
    GROUP BY cust_id
),
     segmentado AS (
         SELECT cust_id, total,
                CASE WHEN total >= 10000 THEN '1-Alto'
                     WHEN total >=  2000 THEN '2-Medio'
                     ELSE '3-Bajo' END AS segmento
         FROM ventas_cliente
     ),
     totales AS (
         SELECT COUNT(*) AS clientes, SUM(total) AS ventas
         FROM segmentado
     )
SELECT s.segmento,
       COUNT(*)                                       AS clientes,
       ROUND(100 * COUNT(*) / MAX(t.clientes), 1)     AS pct_clientes,
       ROUND(100 * SUM(s.total) / MAX(t.ventas), 1)   AS pct_ventas
FROM segmentado s
         CROSS JOIN totales t
GROUP BY s.segmento
ORDER BY s.segmento;


WITH ventas_region_anio AS (
    SELECT co.country_region AS region,
           t.calendar_year AS anio,
           SUM(s.amount_sold) AS ventas
    FROM sh.sales s
             JOIN sh.times t ON s.TIME_ID = t.TIME_ID
             JOIN sh.CUSTOMERS cu ON s.CUST_ID = cu.CUST_ID
             JOIN sh.COUNTRIES co ON cu.COUNTRY_ID = co.COUNTRY_ID
    GROUP BY co.country_region, t.calendar_year
),
     total_region AS (
         SELECT region, SUM(ventas) AS total
         FROM ventas_region_anio
         GROUP BY region
     )
SELECT v.region, v.anio, ROUND(v.ventas) AS ventas, ROUND(t.total) AS total_region
FROM ventas_region_anio v
         JOIN total_region t ON v.region = t.region
WHERE t.total > 5000000
ORDER BY t.total DESC, v.anio;



-- ORDEN DE ESCRITURA
--SELECT    ...
--FROM      ...
--JOIN      ...
--WHERE     ...      -- después de los JOIN
--GROUP BY  ...
--HAVING    ...      -- siempre después del GROUP BY
--ORDER BY  ...      -- siempre al final
