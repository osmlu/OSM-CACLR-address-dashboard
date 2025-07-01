-- Title: Missing city
-- Description: OSM addresses lacking a city tag
SELECT
    osm_id,
    'node' AS osm_type,
    concat('https://osm.org/node/', osm_id) AS url,
    concat('n', osm_id) AS josmuid,
    "addr:housenumber",
    "addr:street",
    "ref:caclr",
    "note:caclr"
FROM planet_osm_point
WHERE "addr:housenumber" IS NOT NULL AND "addr:city" IS NULL
UNION
SELECT
    osm_id,
    'way' AS osm_type,
    concat('https://osm.org/way/', osm_id) AS url,
    concat('w', osm_id) AS josmuid,
    "addr:housenumber",
    "addr:street",
    "ref:caclr",
    "note:caclr"
FROM planet_osm_polygon
WHERE "addr:housenumber" IS NOT NULL AND "addr:city" IS NULL;
