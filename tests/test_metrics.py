import glob
import os

import pytest

from scripts.generate_dashboard import load_metrics


def test_load_metrics():
    metrics = load_metrics("metrics", "includes")
    assert metrics
    for metric in metrics:
        assert metric.slug and metric.sql
        assert isinstance(metric.title, str)
        assert isinstance(metric.description, str)


def test_load_metrics_supports_subdirectories(tmp_path):
    metrics_dir = tmp_path / "metrics"
    nested = metrics_dir / "nested"
    os.makedirs(nested)
    sql_path = nested / "a.sql"
    with open(sql_path, "w", encoding="utf-8") as fh:
        fh.write("-- title: A\n-- description: test\nselect 1;\n")
    loaded = load_metrics(str(metrics_dir), "includes")
    assert any(slug == "a" for slug, *_ in loaded)


def test_osm_potential_addresses_imports():
    for path in glob.glob(os.path.join("metrics", "**", "*.sql"), recursive=True):
        with open(path) as fh:
            content = fh.read()
        if "osm_potential_addresses" in content:
            lower = content.lower()
            assert (
                "-- include osm_potential_addresses.sql" in lower
                or "with osm_potential_addresses" in lower
            ), f"{path} missing osm_potential_addresses snippet"


def test_load_metrics_includes_osm_addresses():
    metric_map = {metric.slug: metric.sql for metric in load_metrics("metrics", "includes")}
    for path in glob.glob(os.path.join("metrics", "**", "*.sql"), recursive=True):
        with open(path) as fh:
            content = fh.read()
        slug = os.path.splitext(os.path.basename(path))[0]
        if "-- include osm_potential_addresses.sql" in content.lower():
            assert "with osm_potential_addresses" in metric_map[slug].lower()


def test_load_metrics_missing_header(tmp_path):
    metric_dir = tmp_path / "metrics"
    include_dir = tmp_path / "inc"
    metric_dir.mkdir()
    include_dir.mkdir()

    metric_path = metric_dir / "a.sql"
    # Missing title
    metric_path.write_text("-- Description: desc\nselect 1;", encoding="utf-8")
    with pytest.raises(ValueError, match="a.sql"):
        load_metrics(str(metric_dir), str(include_dir))

    # Missing description
    metric_path.write_text("-- Title: t\nselect 1;", encoding="utf-8")
    with pytest.raises(ValueError, match="a.sql"):
        load_metrics(str(metric_dir), str(include_dir))

    # Provide both
    metric_path.write_text(
        "-- Title: t\n-- Description: d\nselect 1;",
        encoding="utf-8",
    )
    metrics = load_metrics(str(metric_dir), str(include_dir))
    assert metrics[0][0] == "a"
