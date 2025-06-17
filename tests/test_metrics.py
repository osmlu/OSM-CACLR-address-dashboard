from scripts.generate_dashboard import load_metrics


def test_load_metrics():
    metrics = load_metrics("metrics", "includes")
    assert metrics
    for slug, title, desc, sql in metrics:
        assert slug and sql
        assert isinstance(title, str)
        assert isinstance(desc, str)
