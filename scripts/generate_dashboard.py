#!/usr/bin/env -S uv run
"""Generate the main dashboard as static HTML."""

from __future__ import annotations

import csv
import datetime as dt
import glob
import os
from configparser import ConfigParser

import psycopg2
from psycopg2.pool import ThreadedConnectionPool
from jinja2 import Environment, FileSystemLoader

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt


CONFIG_FILE = os.environ.get("DASHBOARD_CONFIG", "config.ini")


def load_metrics(metric_dir: str, include_dir: str) -> list[tuple[str, str, str, str]]:
    """Load metrics from sql files.

    Returns list of (slug, title, description, sql) tuples.
    """
    metrics: list[tuple[str, str, str, str]] = []
    for path in sorted(
        glob.glob(os.path.join(metric_dir, "**", "*.sql"), recursive=True)
    ):
        slug = os.path.splitext(os.path.basename(path))[0]
        with open(path) as fh:
            lines = fh.readlines()

        title = slug.replace("_", " ").title()
        description = "[No description]"
        sql_lines: list[str] = []
        header = True
        for line in lines:
            stripped = line.strip()
            if stripped.lower().startswith("-- include"):
                parts = stripped.split()
                if len(parts) >= 3:
                    inc_file = os.path.join(include_dir, parts[2])
                    with open(inc_file) as inc:
                        sql_lines.append(inc.read())
                header = False
                continue
            if header and stripped.startswith("--"):
                comment = stripped[2:].strip()
                lower = comment.lower()
                if lower.startswith("title:"):
                    title = comment.split(":", 1)[1].strip()
                elif lower.startswith("description:"):
                    description = comment.split(":", 1)[1].strip()
                else:
                    # ignore other comment lines in header
                    pass
                continue
            header = False
            sql_lines.append(line)

        sql = "".join(sql_lines).strip()

        metrics.append((slug, title, description, sql))
    return metrics


class Dashboard:
    def __init__(self, config: ConfigParser) -> None:
        self.config = config
        self.output_dir = self.config.get("paths", "output_dir", fallback="output")
        self.history_dir = self.config.get("paths", "history_dir", fallback="history")
        os.makedirs(self.output_dir, exist_ok=True)
        os.makedirs(self.history_dir, exist_ok=True)
        os.makedirs(os.path.join(self.output_dir, "img"), exist_ok=True)
        self.env = Environment(loader=FileSystemLoader("templates"))
        self.conn_params = {
            "port": self.config.getint("database", "port", fallback=5432),
            "dbname": self.config.get("database", "dbname"),
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

    def run(self) -> None:
        metric_dir = self.config.get("paths", "metrics_dir", fallback="metrics")
        include_dir = self.config.get("paths", "includes_dir", fallback="includes")
        metrics = []
        metric_defs = list(load_metrics(metric_dir, include_dir))
        results: list[tuple[str, str, str, list[tuple], list[str]]] = []
        from concurrent.futures import ThreadPoolExecutor, as_completed

        with ThreadPoolExecutor() as exe:
            futs = {
                exe.submit(self._fetch_rows, sql): (slug, title, desc)
                for slug, title, desc, sql in metric_defs
            }
            for fut in as_completed(futs):
                slug, title, desc = futs[fut]
                try:
                    rows, headers = fut.result()
                except Exception as exc:  # pragma: no cover - passthrough
                    raise RuntimeError(f"error in metric '{slug}': {exc}") from exc
                results.append((slug, title, desc, rows, headers))

        for slug, title, desc, rows, headers in sorted(results):
            if len(rows) == 1 and len(headers) == 1:
                value = int(rows[0][0] or 0)
                details = None
            else:
                value = len(rows)
                details = {
                    "rows": rows,
                    "headers": headers,
                    "josm": self._josm_link(rows, headers),
                }
            self._update_history(slug, value)
            graph = self._plot_history(slug)
            metrics.append(
                {
                    "slug": slug,
                    "title": title,
                    "description": desc,
                    "value": value,
                    "graph": graph,
                    "details": details,
                }
            )
        template = self.env.get_template("dashboard.html")
        html = template.render(metrics=metrics)
        with open(os.path.join(self.output_dir, "index.html"), "w") as fh:
            fh.write(html)
        self.pool.closeall()

    def _fetch_rows(self, sql: str) -> tuple[list[tuple], list[str]]:
        conn = self.pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(sql)
                rows = cur.fetchall()
                headers = [d[0] for d in cur.description]
        finally:
            self.pool.putconn(conn)
        return rows, headers

    def _update_history(self, slug: str, value: int) -> None:
        path = os.path.join(self.history_dir, f"{slug}.csv")
        is_new = not os.path.exists(path)
        with open(path, "a", newline="") as fh:
            writer = csv.writer(fh)
            if is_new:
                writer.writerow(["date", "value"])
            writer.writerow([dt.date.today().isoformat(), value])

    def _plot_history(self, slug: str) -> str | None:
        path = os.path.join(self.history_dir, f"{slug}.csv")
        if not os.path.exists(path):
            return None
        dates, values = [], []
        try:
            with open(path) as fh:
                reader = csv.DictReader(fh)
                for row in reader:
                    dates.append(dt.datetime.fromisoformat(row["date"]))
                    values.append(int(row["value"]))
        except Exception:
            return None
        if len(values) < 2:
            return None
        plt.figure(figsize=(2.5, 1))
        plt.plot(dates, values, marker="o", linewidth=1, markersize=2)
        plt.xticks([])
        plt.yticks([])
        plt.tight_layout()
        img_path = os.path.join(self.output_dir, "img", f"{slug}.png")
        plt.savefig(img_path)
        plt.close()
        return os.path.relpath(img_path, self.output_dir)

    def _josm_link(self, rows: list[tuple], headers: list[str]) -> str | None:
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


def main() -> None:
    config = ConfigParser()
    config.read(CONFIG_FILE)
    Dashboard(config).run()


if __name__ == "__main__":
    main()
