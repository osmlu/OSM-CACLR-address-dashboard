#!/usr/bin/env -S uv run
"""Export dashboard tables from PostGIS to SpatiaLite.

This dumps the OpenStreetMap and cadastre tables needed for the tests into a
single SpatiaLite file. The OSM portion of the output is
© OpenStreetMap contributors.
"""

from __future__ import annotations

import os
import subprocess
from argparse import ArgumentParser
from configparser import ConfigParser, SectionProxy
from typing import Mapping
from pathlib import Path

CONFIG_FILE = os.environ.get("DASHBOARD_CONFIG", "config.ini")

# Tables needed for the dashboard and metrics
TABLES = [
    "addresses",
    "immeuble",
    "parcelles",
    "planet_osm_point",
    "planet_osm_line",
    "planet_osm_polygon",
]


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
    """Dump all tables to SQLite."""
    for idx, table in enumerate(TABLES):
        args = [
            "ogr2ogr",
            "-f",
            "SQLite",
            "-dsco",
            "SPATIALITE=YES",
        ]
        if idx:
            args.extend(["-update", "-append"])
        args.extend([str(sqlite_path), f"PG:{dsn}", table])
        subprocess.check_call(args)


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
