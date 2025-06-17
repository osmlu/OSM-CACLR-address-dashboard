from jinja2 import Environment, FileSystemLoader


def test_dashboard_template():
    env = Environment(loader=FileSystemLoader("templates"))
    tpl = env.get_template("dashboard.html")
    html = tpl.render(
        metrics=[
            {
                "slug": "test",
                "title": "Test",
                "description": "desc",
                "value": 1,
                "graph": None,
                "details": None,
            }
        ]
    )
    assert "Test" in html
    assert "table" in html
