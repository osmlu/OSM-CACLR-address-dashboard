import glob
import os

from scripts.generate_dashboard import load_metrics


def test_load_metrics():
    metrics = load_metrics("metrics", "includes")
    assert metrics
    for metric in metrics:
        assert metric.slug and metric.sql
        assert isinstance(metric.title, str)
        assert isinstance(metric.description, str)


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
