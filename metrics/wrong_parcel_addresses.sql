-- Title: Wrong parcel matches
-- Description: OSM addresses matching CACLR but placed in a different parcel
-- include osm_potential_addresses_withgeom.sql

-- 8< cut here >8 --
-- comma because we include the
-- osm_potential_addresses_withgeom.sql snippet before this file
, -- noqa: PRS
filtered_osm AS (
  SELECT
    osm_id,
    osm_type,
    osm_user,
    url,
    josmuid,
    osm_timestamp,
    name,
    "addr:housenumber"   AS housenumber,
    "addr:housename"     AS housename,
    "addr:street"        AS street,
    "addr:postcode"      AS postcode,
    "addr:city"          AS city,
    "addr:country"       AS country,
    "ref:caclr",
    note,
    "note:caclr",
    fixme,
    -- project both centroid & raw geometry into 2169 once
    st_transform(st_centroid(way), 2169) AS centroid,
    st_transform(way, 2169)             AS geom2169
  FROM osm_potential_addresses
  WHERE "ref:caclr" IS NULL
),
addresses_prepped AS (
  SELECT
    id_caclr_bat,
    numero::text       AS housenumber,
    rue                AS street,
    code_postal::text  AS postcode,
    localite           AS city,
    id_parcelle,
    st_transform(geom, 2169) AS addr_geom_2169
  FROM addresses
),
immeuble_dates AS (
  SELECT numero_interne, ds_timestamp_modif
  FROM immeuble
),
parcelles_prepped AS (
  SELECT
    id_parcell,
    st_transform(wkb_geometry, 2169) AS parcelle_geom_2169
  FROM parcelles
)

SELECT
  f.osm_id,
  f.osm_type,
  f.osm_user,
  f.url,
  f.josmuid,
  f.osm_timestamp,
  f.name,
  f.housenumber,
  f.housename,
  f.street,
  f.postcode,
  f.city,
  f.country,
  f."ref:caclr",
  f.note,
  f."note:caclr",
  f.fixme,
  a.id_caclr_bat,
  i.ds_timestamp_modif,
  p.id_parcell,
  round(
    st_distance(f.centroid, a.addr_geom_2169)
  ) AS dist,
  st_astext(
    st_shortestline(f.centroid, a.addr_geom_2169)
  ) AS line
FROM filtered_osm AS f
JOIN addresses_prepped AS a
  ON f.housenumber = a.housenumber
 AND f.street      = a.street
 AND f.postcode    = a.postcode
  AND f.city        = a.city
JOIN parcelles_prepped AS p
  ON a.id_parcelle = p.id_parcell
LEFT JOIN immeuble_dates AS i
  ON a.id_caclr_bat = i.numero_interne::text
WHERE NOT st_intersects(f.geom2169, p.parcelle_geom_2169)
  AND st_distance(f.centroid, a.addr_geom_2169) > 10
ORDER BY dist DESC;
