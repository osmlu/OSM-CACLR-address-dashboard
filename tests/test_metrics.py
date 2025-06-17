import glob
import os

from scripts.generate_dashboard import load_metrics


def test_load_metrics():
    metrics = load_metrics("metrics", "includes")
    assert metrics
    for slug, title, desc, sql in metrics:
        assert slug and sql
        assert isinstance(title, str)
        assert isinstance(desc, str)


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
