"""
Mini catálogo de datos (semana 3, integrador).
Recorre el diccionario de Oracle y genera un Markdown por esquema con
tablas, filas estimadas, columnas, tipos, claves y comentarios.

Uso:
    python -m venv .venv && source .venv/bin/activate
    pip install oracledb
    python catalogo.py SH HR
"""
import sys
from datetime import date

import oracledb

DSN = "localhost:1521/FREEPDB1"
USUARIO, CLAVE = "practica", "practica"

SQL_TABLAS = """
    SELECT t.table_name, t.num_rows, c.comments
    FROM all_tables t
    LEFT JOIN all_tab_comments c
           ON c.owner = t.owner AND c.table_name = t.table_name
    WHERE t.owner = :owner
    ORDER BY t.table_name"""

SQL_COLUMNAS = """
    SELECT c.column_name, c.data_type, c.data_length, c.data_precision,
           c.data_scale, c.nullable, cc.comments
    FROM all_tab_columns c
    LEFT JOIN all_col_comments cc
           ON cc.owner = c.owner AND cc.table_name = c.table_name
          AND cc.column_name = c.column_name
    WHERE c.owner = :owner AND c.table_name = :tabla
    ORDER BY c.column_id"""

SQL_CLAVES = """
    SELECT a.constraint_type, col.column_name, ref.table_name AS tabla_ref
    FROM all_constraints a
    JOIN all_cons_columns col
      ON col.owner = a.owner AND col.constraint_name = a.constraint_name
    LEFT JOIN all_constraints ref
      ON ref.owner = a.r_owner AND ref.constraint_name = a.r_constraint_name
    WHERE a.owner = :owner AND a.table_name = :tabla
      AND a.constraint_type IN ('P', 'R')"""


def tipo(dt, largo, precision, escala):
    if dt in ("VARCHAR2", "CHAR", "NVARCHAR2"):
        return f"{dt}({largo})"
    if dt == "NUMBER" and precision is not None:
        return f"NUMBER({precision},{escala or 0})"
    return dt


def documentar(cur, owner):
    lineas = [f"# Catálogo del esquema {owner}", f"Generado el {date.today():%d/%m/%Y}", ""]
    sin_comentario = total_cols = 0
    cur.execute(SQL_TABLAS, owner=owner)
    tablas = cur.fetchall()
    for tabla, filas, comentario in tablas:
        claves = {}
        cur.execute(SQL_CLAVES, owner=owner, tabla=tabla)
        for tipo_c, col, ref in cur.fetchall():
            claves.setdefault(col, []).append("PK" if tipo_c == "P" else f"FK → {ref}")
        lineas += [f"## {tabla}", "",
                   f"Filas estimadas: {filas if filas is not None else 'sin estadísticas'}",
                   "", comentario or "_Sin descripción._", "",
                   "| Columna | Tipo | Nulos | Claves | Descripción |",
                   "| --- | --- | --- | --- | --- |"]
        cur.execute(SQL_COLUMNAS, owner=owner, tabla=tabla)
        for col, dt, largo, prec, esc, nulos, com in cur.fetchall():
            total_cols += 1
            sin_comentario += com is None
            lineas.append(f"| {col} | {tipo(dt, largo, prec, esc)} | "
                          f"{'sí' if nulos == 'Y' else 'no'} | {', '.join(claves.get(col, []))} | "
                          f"{com or ''} |")
        lineas.append("")
    pct = 100 * sin_comentario / total_cols if total_cols else 0
    lineas.insert(3, f"**{len(tablas)} tablas, {total_cols} columnas. "
                     f"Columnas sin descripción: {sin_comentario} ({pct:.0f} %).**\n")
    archivo = f"catalogo_{owner.lower()}.md"
    with open(archivo, "w", encoding="utf-8") as f:
        f.write("\n".join(lineas))
    print(f"{owner}: {len(tablas)} tablas, {total_cols} columnas, "
          f"{pct:.0f} % sin descripción -> {archivo}")


if __name__ == "__main__":
    esquemas = [e.upper() for e in sys.argv[1:]] or ["SH"]
    with oracledb.connect(user=USUARIO, password=CLAVE, dsn=DSN) as con:
        with con.cursor() as cur:
            for esquema in esquemas:
                documentar(cur, esquema)
