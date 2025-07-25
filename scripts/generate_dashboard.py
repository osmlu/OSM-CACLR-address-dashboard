#!/usr/bin/env -S uv run
"""Generate the main dashboard as static HTML."""

from __future__ import annotations

import csv
import datetime as dt
import glob
import logging
import os
from concurrent.futures import ThreadPoolExecutor, as_completed
from decimal import Decimal
from configparser import ConfigParser
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import quote

from jinja2 import Environment, FileSystemLoader, select_autoescape
from psycopg2.pool import ThreadedConnectionPool
from rich.logging import RichHandler

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(markup=True, rich_tracebacks=True)],
)

# Default configuration file path
CONFIG_FILE = os.environ.get("DASHBOARD_CONFIG", "config.ini")


@dataclass(slots=True, kw_only=True)
class Metric:
    """Simple container for metric properties."""

    slug: str
    title: str
    description: str
    sql: str


def load_metrics(metric_dir: str, include_dir: str) -> list[Metric]:
    """Load metrics from sql files."""
    metrics: list[Metric] = []
    pattern = os.path.join(metric_dir, "**", "*.sql")
    for path in sorted(glob.glob(pattern, recursive=True)):
        slug = os.path.splitext(os.path.basename(path))[0]
        with open(path, encoding="utf-8") as fh:
            lines = fh.readlines()

        title = slug.replace("_", " ").title()
        description = "[No description]"
        has_title = False
        has_description = False
        sql_lines: list[str] = []
        header = True
        for line in lines:
            stripped = line.strip()
            if stripped.lower().startswith("-- include"):
                parts = stripped.split()
                if len(parts) >= 3:
                    inc_file = os.path.join(include_dir, parts[2])
                    with open(inc_file, encoding="utf-8") as inc:
                        sql_lines.append(inc.read())
                header = False
                continue
            if header and stripped.startswith("--"):
                comment = stripped[2:].strip()
                lower = comment.lower()
                if lower.startswith("title:"):
                    title = comment.split(":", 1)[1].strip()
                    has_title = True
                elif lower.startswith("description:"):
                    description = comment.split(":", 1)[1].strip()
                    has_description = True
                else:
                    # ignore other comment lines in header
                    pass
                continue
            header = False
            sql_lines.append(line)

        if not has_title or not has_description:
            raise ValueError(f"{os.path.basename(path)} missing title or description")

        sql = "".join(sql_lines).strip()

        metrics.append(Metric(slug=slug, title=title, description=description, sql=sql))
    return metrics


class Dashboard:
    """Generate the dashboard from metrics."""

    def __init__(self: Dashboard, config: ConfigParser) -> None:
        self.config = config
        self.output_dir = Path(self.config.get("paths", "output_dir", fallback="output"))
        self.history_dir = Path(self.config.get("paths", "history_dir", fallback="history"))
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.history_dir.mkdir(parents=True, exist_ok=True)
        self.env = Environment(
            loader=FileSystemLoader("templates", encoding="utf-8"),
            autoescape=select_autoescape(["html", "xml"]),
        )
        self.conn_params = {
            "port": self.config.getint("database", "port", fallback=5432),
            "dbname": self.config.get("database", "dbname"),
            "application_name": "osm-caclr-dashboard",
            "user": self.config.get("database", "user"),
        }
        host = self.config.get("database", "host", fallback="")
        if host:
            self.conn_params["host"] = host
        password = self.config.get("database", "password", fallback="")
        if password:
            self.conn_params["password"] = password
        max_conn = self.config.getint("database", "max_connections", fallback=32)
        self.pool = ThreadedConnectionPool(1, max_conn, **self.conn_params)

    def run(self: Dashboard) -> None:
        """Run the dashboard generation with all metrics."""
        metric_dir = self.config.get("paths", "metrics_dir", fallback="metrics")
        include_dir = self.config.get("paths", "includes_dir", fallback="includes")
        metrics = []
        start = dt.datetime.now()
        metric_defs = list(load_metrics(metric_dir, include_dir))
        logging.info(
            "[cyan]Loaded %d metrics in %.2fs[/cyan]",
            len(metric_defs),
            (dt.datetime.now() - start).total_seconds(),
        )
        results: list[tuple[Metric, list[tuple], list[str]]] = []

        with ThreadPoolExecutor() as exe:
            futs = {
                exe.submit(self._fetch_rows, m.sql): (m, dt.datetime.now()) for m in metric_defs
            }
            for fut in as_completed(futs):
                metric, start_t = futs[fut]
                try:
                    rows, headers = fut.result()
                    rows = self._convert_rows(rows)
                except Exception as exc:  # pragma: no cover - passthrough
                    raise RuntimeError(f"error in metric '{metric.slug}': {exc}") from exc
                logging.info(
                    "[blue]Query '%s' returned %d rows in %.2fs[/blue]",
                    metric.slug,
                    len(rows),
                    (dt.datetime.now() - start_t).total_seconds(),
                )
                results.append((metric, rows, headers))

        for metric, rows, headers in sorted(results, key=lambda r: r[0].slug):
            if len(rows) == 1 and len(headers) == 1:
                value = int(rows[0][0] or 0)
                details = None
            else:
                value = len(rows)
                details = {
                    "rows": rows,
                    "headers": headers,
                    "josm": self._josm_link(rows, headers),
                    "overpass": self._overpass_link(rows, headers),
                }
            self._update_history(metric.slug, value)
            graph = self._plot_history(metric.slug)
            metrics.append(
                {
                    "slug": metric.slug,
                    "title": metric.title,
                    "description": metric.description,
                    "value": value,
                    "graph": graph,
                    "details": details,
                },
            )

        metrics.sort(key=lambda m: (m["value"] == 0, m["title"].lower()))
        start = dt.datetime.now()
        template = self.env.get_template("dashboard.html")
        html = template.render(metrics=metrics)
        out_file = self.output_dir / "index.html"
        with out_file.open("w", encoding="utf-8") as fh:
            fh.write(html)
        logging.info(
            "[green]Wrote HTML in %.2fs to %s[/green]",
            (dt.datetime.now() - start).total_seconds(),
            out_file,
        )
        self.pool.closeall()

    def _fetch_rows(self: Dashboard, sql: str) -> tuple[list[tuple], list[str]]:
        conn = self.pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()
                headers = [d[0] for d in cur.description]
        finally:
            self.pool.putconn(conn)
        return rows, headers

    def _convert_rows(self: Dashboard, rows: list[tuple]) -> list[tuple]:
        """Convert non-JSON serialisable types to basic Python types."""
        converted: list[tuple] = []
        for row in rows:
            new_row = []
            for val in row:
                if isinstance(val, Decimal):
                    new_row.append(float(val))
                elif isinstance(val, (dt.date, dt.datetime)):
                    new_row.append(val.isoformat())
                else:
                    new_row.append(val)
            converted.append(tuple(new_row))
        return converted

    def _update_history(self: Dashboard, slug: str, value: int) -> None:
        path = self.history_dir / f"{slug}.csv"
        is_new = not path.exists()
        with path.open("a", newline="", encoding="utf-8") as fh:
            writer = csv.writer(fh)
            if is_new:
                writer.writerow(["date", "value"])
            writer.writerow([dt.date.today().isoformat(), value])

    def _plot_history(self: Dashboard, slug: str) -> dict[str, list] | None:
        path = self.history_dir / f"{slug}.csv"
        if not path.exists():
            return None
        dates: list[str] = []
        values: list[int] = []
        try:
            with path.open(encoding="utf-8") as fh:
                reader = csv.DictReader(fh)
                for row in reader:
                    dates.append(row["date"])
                    values.append(int(row["value"]))
        except (csv.Error, ValueError, TypeError, KeyError) as exc:
            raise RuntimeError(f"error reading history for '{slug}': {exc}") from exc
        if len(values) < 2:
            return None
        return {"dates": dates, "values": values}

    def _josm_link(self: Dashboard, rows: list[tuple], headers: list[str]) -> str | None:
        if "osm_id" not in headers or "osm_type" not in headers:
            return None
        id_idx = headers.index("osm_id")
        type_idx = headers.index("osm_type")
        objects = []
        for row in rows:
            prefix = row[type_idx][0]
            objects.append(f"{prefix}{row[id_idx]}")
        url_tpl = self.config.get("general", "josm_remote_url")
        return url_tpl.format(object_ids=",".join(objects))

    def _overpass_link(self: Dashboard, rows: list[tuple], headers: list[str]) -> str | None:
        if "osm_id" not in headers or "osm_type" not in headers:
            return None
        id_idx = headers.index("osm_id")
        type_idx = headers.index("osm_type")
        parts = [f"{rows[i][type_idx]}({rows[i][id_idx]})" for i in range(len(rows))]
        query = "[out:json];" + "".join(f"{p};" for p in parts) + "out geom;"
        return f"https://overpass-turbo.eu/?Q={quote(query)}&R"


def main() -> None:
    """Run dashboard generation."""
    if not os.path.exists(CONFIG_FILE):
        raise FileNotFoundError(f"Configuration file '{CONFIG_FILE}' not found.")
    if not os.path.isfile(CONFIG_FILE):
        raise IsADirectoryError(f"Configuration file '{CONFIG_FILE}' is not a file.")
    config = ConfigParser()
    config.read(CONFIG_FILE)
    Dashboard(config).run()


if __name__ == "__main__":
    main()
