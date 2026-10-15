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