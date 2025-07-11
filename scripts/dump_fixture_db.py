#!/usr/bin/env -S uv run
"""Export dashboard tables from PostGIS to a compressed SpatiaLite file.

This script creates a small-ish fixture database by exporting only the rows
needed by the metrics. The OSM part of the dump is © OpenStreetMap
contributors.
"""

from __future__ import annotations

import os
import subprocess
from argparse import ArgumentParser
from configparser import ConfigParser, SectionProxy
from pathlib import Path
from typing import Mapping

CONFIG_FILE = os.environ.get("DASHBOARD_CONFIG", "config.ini")

ADDR_CONDITION = " OR ".join(
    f'"{tag}" IS NOT NULL'
    for tag in (
        "addr:housenumber",
        "addr:housename",
        "addr:street",
        "addr:place",
        "addr:postcode",
        "addr:city",
        "addr:country",
    )
)

QUERIES = {
    "addresses": """
        SELECT id_caclr_bat, id_caclr_rue, numero, rue, localite,
               code_postal, id_parcelle, geom
        FROM addresses
    """,
    "immeuble": """
        SELECT numero_interne, ds_timestamp_modif
        FROM immeuble
    """,
    "planet_osm_point": f"""
        SELECT osm_id, osm_user, osm_timestamp, name,
               "addr:housenumber", "addr:housename", "addr:street",
               "addr:postcode", "addr:city", "addr:country",
               "ref:caclr", note, "note:caclr", fixme, way
        FROM planet_osm_point
        WHERE {ADDR_CONDITION}
    """,
    "planet_osm_line": f"""
        SELECT osm_id, osm_user, osm_timestamp, name,
               "addr:housenumber", "addr:housename", "addr:street",
               "addr:postcode", "addr:city", "addr:country",
               "ref:caclr", note, "note:caclr", fixme,
               "addr:interpolation", way
        FROM planet_osm_line
        WHERE {ADDR_CONDITION} OR "addr:interpolation" IS NOT NULL
    """,
    "planet_osm_polygon": f"""
        SELECT osm_id, osm_user, osm_timestamp, name,
               "addr:housenumber", "addr:housename", "addr:street",
               "addr:postcode", "addr:city", "addr:country",
               "ref:caclr", note, "note:caclr", fixme, way
        FROM planet_osm_polygon
        WHERE {ADDR_CONDITION}
    """,
}

QUERIES[
    "parcelles"
] = f"""
    SELECT p.id_parcell, p.wkb_geometry
    FROM parcelles AS p
    WHERE EXISTS (
            SELECT 1 FROM addresses a
            WHERE a.id_parcelle = p.id_parcell
        )
        OR EXISTS (
            SELECT 1 FROM planet_osm_point pt
            WHERE ({ADDR_CONDITION}) AND ST_Intersects(pt.way, p.wkb_geometry)
        )
        OR EXISTS (
            SELECT 1 FROM planet_osm_polygon po
            WHERE ({ADDR_CONDITION}) AND ST_Intersects(po.way, p.wkb_geometry)
        )
        OR EXISTS (
            SELECT 1 FROM planet_osm_line li
            WHERE (({ADDR_CONDITION}) OR "addr:interpolation" IS NOT NULL)
              AND ST_Intersects(li.way, p.wkb_geometry)
        )
"""



def build_dsn(db: Mapping[str, str] | SectionProxy) -> str:
    """Build libpq connection string for ogr2ogr."""
    parts = [f"port={db.get('port', '5432')}", f"dbname={db['dbname']}"]
    host = db.get("host")
    if host:
        parts.append(f"host={host}")
    user = db.get("user")
    if user:
        parts.append(f"user={user}")
    password = db.get("password")
    if password:
        parts.append(f"password={password}")
    return " ".join(parts)


def export_tables(sqlite_path: Path, dsn: str) -> None:
    """Dump filtered tables to SQLite."""
    for idx, (name, sql) in enumerate(QUERIES.items()):
        args = [
            "ogr2ogr",
            "-f",
            "SQLite",
            "-dsco",
            "SPATIALITE=YES",
        ]
        if idx:
            args.extend(["-update", "-append"])
        args.extend(
            [
                str(sqlite_path),
                f"PG:{dsn}",
                "-nln",
                name,
                "-sql",
                sql,
            ]
        )
        subprocess.check_call(args)

    subprocess.check_call(["zstd", "-19", "-T0", str(sqlite_path)])
    sqlite_path.unlink(missing_ok=True)


def main() -> None:
    parser = ArgumentParser(description=__doc__)
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        default=Path("tests/fixture.sqlite"),
        help="Path to output SQLite database",
    )
    args = parser.parse_args()

    if not os.path.exists(CONFIG_FILE):
        raise FileNotFoundError(f"Configuration file '{CONFIG_FILE}' not found.")

    cfg = ConfigParser()
    cfg.read(CONFIG_FILE)

    dsn = build_dsn(cfg["database"])
    export_tables(args.output, dsn)


if __name__ == "__main__":
    main()
