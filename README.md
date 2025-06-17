# OSM-CACLR-address-dashboard

This repository contains scripts to generate a static HTML dashboard for the Luxembourg address import. The dashboard is intended to be run via `cron` and does not require any CGI components.
The code targets **Python 3.12** and uses the [uv](https://github.com/astral-sh/uv) package manager which will be installed automatically when running the scripts.

## Configuration

Copy `config.ini` and adapt the database connection settings and output paths.
The configuration file is read automatically when running the scripts. It also
contains paths for the output directory, history data and the locations of the
metric SQL files and includes. Connection parameters like `host` and `password`
may be left blank when using socket based authentication.
Queries used for the metrics live in the directory configured with
`metrics_dir` (default `metrics`) as individual SQL files. Metrics can be
organised in sub-directories such as `cleanup/` and `context/`. Optional
snippets can be placed in the directory configured by `includes_dir` (default
`includes`) and referenced from the metrics using a comment of the form
`-- include FILE.sql`. Each SQL file should start with two comment lines: one for
the title and one for the description. These are shown on the dashboard.

## Generating the dashboard

```
./scripts/generate_dashboard.py
```

This will create `index.html` and small trend graphs inside the directory
specified by `output_dir` in the configuration file. Each metric row can be
expanded to show the underlying rows, and if the query returns OSM IDs a "Load
in JOSM" link is offered. The script uses an
[uv](https://github.com/astral-sh/uv) shebang to automatically install its Python dependencies.
Queries run concurrently so the dashboard builds quickly.

### Running the tests

```
uv run pytest
```

### Code style

Python code is formatted with `black` and linted with `ruff`. SQL files are
checked with `sqlfluff`. These run automatically via GitHub Actions.

## Programmatic checks

Run the following command before committing changes:

```
python -m py_compile $(git ls-files '*.py')
```

## Database schema

The scripts expect two tables to be available:

`addresses` with at least the columns
`id_caclr_bat`, `id_caclr_rue`, `numero`, `rue`, `localite`, `code_postal`,
`geom` (geometry in EPSG:4326) and optional `lat_wgs84`/`lon_wgs84` numeric
columns.

`parcelles` with a primary key `id_parcell` and a polygon column
`wkb_geometry` in EPSG:4326 used when checking wrong parcel matches.
