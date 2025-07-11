import os
from configparser import ConfigParser
from unittest.mock import patch
import logging

import pytest

from scripts.generate_dashboard import Dashboard


class DummyPool:
    def __init__(self, *a, **kw):
        pass

    def getconn(self):
        return None

    def putconn(self, conn):
        pass

    def closeall(self):
        pass


def make_config(tmp_path):
    cfg = ConfigParser()
    cfg["database"] = {"dbname": "db", "user": "user"}
    cfg["paths"] = {
        "output_dir": str(tmp_path / "out"),
        "history_dir": str(tmp_path / "hist"),
        "metrics_dir": str(tmp_path / "metrics"),
        "includes_dir": str(tmp_path / "inc"),
    }
    cfg["general"] = {"josm_remote_url": "josm://{object_ids}"}
    for sec in ["output_dir", "history_dir", "metrics_dir", "includes_dir"]:
        os.makedirs(cfg["paths"][sec], exist_ok=True)
    return cfg


def make_dashboard(cfg):
    with patch("scripts.generate_dashboard.ThreadedConnectionPool", DummyPool):
        return Dashboard(cfg)


def test_josm_overpass_links(tmp_path):
    dash = make_dashboard(make_config(tmp_path))
    rows = [(1, "way"), (2, "node")]
    headers = ["osm_id", "osm_type"]
    josm = dash._josm_link(rows, headers)
    assert josm.endswith("w1,n2")
    overpass = dash._overpass_link(rows, headers)
    from urllib.parse import unquote

    assert "overpass-turbo" in overpass
    decoded = unquote(overpass)
    assert "way(1)" in decoded and "node(2)" in decoded


def test_history_and_plot(tmp_path):
    dash = make_dashboard(make_config(tmp_path))
    dash._update_history("m", 5)
    hist = os.path.join(dash.history_dir, "m.csv")
    assert os.path.exists(hist)
    assert dash._plot_history("m") is None
    dash._update_history("m", 3)
    data = dash._plot_history("m")
    assert data is not None
    assert data["values"] == [5, 3]
    assert len(data["dates"]) == 2


def test_run_creates_html(tmp_path, caplog):
    cfg = make_config(tmp_path)
    metric_dir = cfg["paths"]["metrics_dir"]
    with open(os.path.join(metric_dir, "a.sql"), "w", encoding="utf-8") as fh:
        fh.write("-- Title: A\n-- Description: d\nselect 1 as col;\n")
    dash = make_dashboard(cfg)
    with caplog.at_level(logging.INFO):
        with patch.object(dash, "_fetch_rows", return_value=([(1,)], ["col"])):
            dash.run()
    index = os.path.join(cfg["paths"]["output_dir"], "index.html")
    assert os.path.exists(index)
    log_text = caplog.text
    assert "Loaded 1 metrics" in log_text
    assert "Query 'a' returned 1 rows" in log_text
    assert "Wrote HTML" in log_text


def test_plot_history_corrupted_file(tmp_path):
    dash = make_dashboard(make_config(tmp_path))
    slug = "bad"
    dash._update_history(slug, 1)
    hist = dash.history_dir / f"{slug}.csv"
    with hist.open("a", encoding="utf-8") as fh:
        fh.write("bad_line\n")
    with pytest.raises(RuntimeError):
        dash._plot_history(slug)


def test_update_history_no_duplicate_headers(tmp_path):
    dash = make_dashboard(make_config(tmp_path))
    slug = "dup"
    dash._update_history(slug, 1)
    dash._update_history(slug, 2)
    hist = dash.history_dir / f"{slug}.csv"
    with hist.open(encoding="utf-8") as fh:
        lines = [line.strip() for line in fh.readlines()]
    assert lines[0] == "date,value"
    assert lines.count("date,value") == 1


def test_run_handles_decimal_results(tmp_path):
    cfg = make_config(tmp_path)
    metric_dir = cfg["paths"]["metrics_dir"]
    with open(os.path.join(metric_dir, "dec.sql"), "w", encoding="utf-8") as fh:
        fh.write("-- Title: D\n-- Description: d\nselect 1.5 as col;\n")
    dash = make_dashboard(cfg)
    from decimal import Decimal

    with patch.object(dash, "_fetch_rows", return_value=([(Decimal("1.5"),)], ["col"])):
        dash.run()
    index = os.path.join(cfg["paths"]["output_dir"], "index.html")
    assert os.path.exists(index)


def test_run_handles_date_results(tmp_path):
    cfg = make_config(tmp_path)
    metric_dir = cfg["paths"]["metrics_dir"]
    with open(os.path.join(metric_dir, "date.sql"), "w", encoding="utf-8") as fh:
        fh.write("-- Title: D\n-- Description: d\nselect CURRENT_DATE as col;\n")
    dash = make_dashboard(cfg)
    from datetime import date

    with patch.object(
        dash,
        "_fetch_rows",
        return_value=([(date.today(), 1)], ["col", "num"]),
    ):
        dash.run()
    index = os.path.join(cfg["paths"]["output_dir"], "index.html")
    assert os.path.exists(index)


def test_metrics_sorted_zero_last(tmp_path):
    cfg = make_config(tmp_path)
    metric_dir = cfg["paths"]["metrics_dir"]
    with open(os.path.join(metric_dir, "a.sql"), "w", encoding="utf-8") as fh:
        fh.write("-- Title: A\n-- Description: d\nselect 0 as col;\n")
    with open(os.path.join(metric_dir, "b.sql"), "w", encoding="utf-8") as fh:
        fh.write("-- Title: B\n-- Description: d\nselect 1 as col;\n")
    dash = make_dashboard(cfg)

    def fake_fetch(sql: str):
        if "select 1" in sql:
            return ([(1,)], ["col"])
        return ([(0,)], ["col"])

    with patch.object(dash, "_fetch_rows", side_effect=fake_fetch):
        dash.run()

    index = os.path.join(cfg["paths"]["output_dir"], "index.html")
    html = open(index, encoding="utf-8").read()
    assert html.index("<strong>B</strong>") < html.index("<strong>A</strong>")
