# OSM-CACLR-address-dashboard

This repository contains scripts to generate a static HTML dashboard for the Luxembourg address import. The dashboard is intended to be run via `cron` and does not require any CGI components.
The code targets **Python 3.12** and uses the [uv](https://github.com/astral-sh/uv) package manager which will be installed automatically when running the scripts.

## Configuration

Copy `config.ini` and adapt the database connection settings and output paths.
The configuration file is read automatically when running the scripts. You can
override its location by setting the `DASHBOARD_CONFIG` environment variable. It also
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

This will create `index.html` with dynamic trend graphs powered by Chart.js
inside the directory specified by `output_dir` in the configuration file.
Each metric row can be expanded to show the underlying rows, and if the
query returns OSM IDs a "Load in JOSM" link is offered. The script uses an
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

The dashboard queries a small set of tables. Only a subset of the columns is
strictly required, but the complete definitions can be useful when preparing the
database used by the scripts or when building AI agents that interact with the
data. The main tables are `addresses`, `immeuble` and `parcelles` along with the
standard OpenStreetMap tables created by `osm2pgsql`.

`immeuble` and several supporting lookup tables originate from the complete
[CACLR database](https://data.public.lu/en/datasets/registre-national-des-localites-et-des-rues/).
They are imported from the fixed-width files using lowercase table names.

### `addresses`

Official address points published by the Administration du Cadastre et de la Topographie (ACT). Each row represents a
single geocoded address with various identifiers and coordinates. All geocoded
addresses in this table also appear in `immeuble`, although not every entry in
`immeuble` has coordinates yet.
```
Column            Type
----------------- ------------------------------------
rue_orig          character varying(64)
code_commune      integer
rue               character varying(64)
numero            character varying(256)
localite          character varying(64)
code_postal       numeric(4,0)
id_caclr_rue      numeric(5,0)
id_caclr_bat      character varying(512)
lat_wgs84         double precision
lon_wgs84         double precision
coord_est_luref   double precision
coord_nord_luref  double precision
id_geoportail     character varying(32)
commune           character varying(32)
lau2              character varying(4)
geom              geometry(Point,4326)
geom_3857         geometry(Point,3857)
id_parcelle       character varying(15)
```

The scripts only rely on `id_caclr_bat`, `id_caclr_rue`, `numero`, `rue`,
`localite`, `code_postal` and `geom`, but the other columns are commonly present
in the official data export.

### `immeuble`

Building numbers and related metadata. The table links a house number to a
street (`fk_rue_numero`) and holds flags indicating if the number is temporary
or undefined.

```
Column            Type
----------------- -----------------------
numero_interne    numeric(8,0) PRIMARY KEY
numero            numeric(3,0)
code_multiple     character varying(6)
date_fin_valid    date
ds_timestamp_modif date
fk_codpt_numero   numeric(4,0)
fk_quart_numero   numeric(5,0)
fk_rue_numero     numeric(5,0)
indic_no_indef    character(1)
indic_provisoire  character(1)
designation       character varying(40)
```

`numero_interne` is the same key as `id_caclr_bat` in the `addresses` table and
is tagged as `ref:caclr` in OSM. `indic_provisoire` equals `O` for unvalidated
records that should not be treated as reliable. `indic_no_indef` is set to `O`
for technical "zero" addresses that merely attach postal codes to a street with
no house numbers. Regular validated addresses have `indic_no_indef` set to `N`.

AI agents can rely on this mapping to correlate `addresses` with building
records.

The scripts cross-reference `fk_rue_numero` with street segments.

### `parcelles`

Cadastral parcels from the Administration du Cadastre et de la Topographie. These polygons are used to ensure
addresses are placed on the correct parcel.
```
Column      Type
----------- -----------------------------
ogc_fid     integer PRIMARY KEY
id_parcell  character varying(15)
code_commu  numeric(10,0)
code_secti  character varying(1)
numero_pri  numeric(10,0)
numero_sec  numeric(10,0)
lieudit     character varying(30)
code_natur  numeric(10,0)
wkb_geometry geometry(MultiPolygon,3857)
```

`wkb_geometry` is used to verify parcel matches.

### OSM tables

Many metrics join against the tables generated by `osm2pgsql`
(`planet_osm_point`, `planet_osm_line` and `planet_osm_polygon`). Temporary
views such as `osm_potential_addresses` are built from these sources. The
`immeuble` table is also consulted when resolving building numbers.

### `code_postal`

Postal codes linked to towns or delivery areas.
```
Column             Type
------------------ -----------------
numero_postal      char(4)
lib_post_majuscule char(40)
type_cp            char(1)
limite_inf_bp      numeric(4)
limite_sup_bp      numeric(4)
ds_timestamp_modif date
```

### `commune`

Municipalities. `fk_canto_code` references a canton.
```
Column           Type
---------------- -----------------
code             numeric(2)
nom              char(40)
nom_majuscule    char(40)
ds_timestamp_modif date
fk_canto_code    numeric(2)
```

### `canton`

Cantons referencing a district.
```
Column           Type
---------------- -----------------
code             numeric(2)
nom              char(40)
ds_timestamp_modif date
fk_distr_code    char(4)
```

### `district_admin`

Administrative districts.
```
Column             Type
------------------ -----------------
code               char(4)
nom                char(40)
ds_timestamp_modif date
```

### `localite`

Localities linked to a commune/canton.
```
Column             Type
------------------ -----------------
numero             numeric(5)
nom                char(40)
nom_majuscule      char(40)
code               numeric(2)
indic_ville        char(1)
date_fin_valid     date
ds_timestamp_modif date
fk_canto_code      numeric(2)
fk_commu_code      numeric(2)
```

### `rue`

Street records imported from CACLR with links to the locality, commune and canton.
The table includes a street identifier (`numero`), the official name and other
metadata such as uppercase variants and timestamps. *(Full column list to be
added once available.)*
