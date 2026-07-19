#!/usr/bin/env -S uv run
"""Run dashboard metrics against the SQLite fixture."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import TYPE_CHECKING, Sequence

if not __package__:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# pylint: disable-next=wrong-import-position
from scripts.generate_dashboard import load_metrics  # noqa: E402

# if type checking, import sqlite3 from the standard library
# otherwise, try to import pysqlite3 for better SQLite support
if TYPE_CHECKING:
    import sqlite3
else:
    try:
        import pysqlite3 as sqlite3
    except ImportError:
        import sqlite3


def concat(*args: Sequence[object]) -> str:
    """Concatenate values for SQLite's variadic ``concat`` function."""
    return "".join(str(a) for a in args)


def regexp(pattern: str, value: object) -> int:
    """Implement SQLite's ``regexp`` function using Python regular expressions."""
    if value is None:
        return 0
    return 1 if re.search(pattern, str(value)) else 0


def adapt_sql(sql: str) -> str:
    """Lightweight translation of Postgres SQL to SQLite."""
    # Drop postgres style casts
    sql = re.sub(r"::\w+", "", sql)
    # Replace regex operators
    sql = re.sub(r"([\w:\".]+)\s*!~\s*'([^']*)'", r"NOT regexp('\2', \1)", sql)
    sql = re.sub(r"([\w:\".]+)\s*~\s*'([^']*)'", r"regexp('\2', \1)", sql)
    # Replace ILIKE with case-insensitive LIKE
    sql = re.sub(r"\bILIKE\b", "LIKE", sql, flags=re.IGNORECASE)
    # Replace string_agg with group_concat
    sql = re.sub(r"String_agg", "group_concat", sql, flags=re.IGNORECASE)
    # Drop columns not present in the fixture
    sql = sql.replace("i.date_fin_valid,", "")
    sql = sql.replace("opa.way && caclr.geom_3857 AND ", "")
    sql = re.sub(r"\blat_wgs84\b", "ST_Y(geom)", sql)
    return re.sub(r"\blon_wgs84\b", "ST_X(geom)", sql)


def run(
    db_path: Path,
    metric_dir: str = "metrics",
    include_dir: str = "includes",
    only: str | None = None,
) -> None:
    """Run all, or one, dashboard metrics against a SQLite fixture."""
    conn = sqlite3.connect(db_path)
    conn.enable_load_extension(True)
    conn.load_extension("mod_spatialite")
    conn.create_function("concat", -1, concat)
    conn.create_function("regexp", 2, regexp)

    metrics = load_metrics(metric_dir, include_dir)
    if only:
        metrics = [m for m in metrics if m.slug == only]
    for metric in metrics:
        sql = adapt_sql(metric.sql)
        try:
            cur = conn.execute(sql)
            rows = cur.fetchall()
            print(f"{metric.slug}: {len(rows)} rows")
        except Exception as exc:  # pragma: no cover  # pylint: disable=broad-exception-caught
            print(f"{metric.slug}: ERROR {exc}")

    conn.close()


def main() -> None:
    """Parse command-line arguments and run fixture metrics."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "db", type=Path, nargs="?", default=Path("tests/fixture.sqlite"), help="Path to SQLite DB"
    )
    parser.add_argument("--metric", help="Run only a single metric")
    args = parser.parse_args()
    run(args.db, only=args.metric)


if __name__ == "__main__":
    main()
