-- Title: Far matches
-- Description: OSM addresses matching CACLR but located more than 30m away
-- include osm_potential_addresses_withgeom.sql

-- 8< cut here >8 --
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
      "addr:street"        AS street,
      "addr:postcode"      AS postcode,
      "addr:city"          AS city,
      "ref:caclr",
      note,
      "note:caclr",
      st_transform(st_centroid(way), 2169) AS centroid
    FROM osm_potential_addresses
    WHERE "ref:caclr" IS NULL
),
addresses_prepped AS (
    SELECT
      id_caclr_bat,
      numero::text      AS housenumber,
      rue               AS street,
      code_postal::text AS postcode,
      localite          AS city,
      st_transform(geom, 2169) AS geom2169
    FROM addresses
),
immeuble_dates AS (
    SELECT numero_interne, ds_timestamp_modif
    FROM immeuble
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
  f.street,
  f.postcode,
  f.city,
  f."ref:caclr",
  f.note,
  f."note:caclr",
  a.id_caclr_bat,
  i.ds_timestamp_modif,
  st_distance(f.centroid, a.geom2169) AS dist,
  st_astext(st_shortestline(f.centroid, a.geom2169)) AS line
FROM filtered_osm AS f
JOIN addresses_prepped AS a
  ON f.housenumber = a.housenumber
 AND f.street      = a.street
 AND f.postcode    = a.postcode
 AND f.city        = a.city
LEFT JOIN immeuble_dates AS i
  ON a.id_caclr_bat = i.numero_interne::text
WHERE st_distance(f.centroid, a.geom2169) > 30
ORDER BY dist DESC;
