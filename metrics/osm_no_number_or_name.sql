-- Title: OSM objects without number or name
-- Description: Objects with addr:street but neither housenumber nor housename
WITH osm_potential_addresses AS (
    SELECT
osm_id,
'node' AS osm_type,
           concat('https://osm.org/node/', osm_id) AS url,
           concat('n', osm_id) AS josmuid,
           "addr:housenumber",
"addr:housename",
"addr:street",
           "ref:caclr",
"note:caclr"
    FROM planet_osm_point
    WHERE "addr:street" IS NOT NULL
    UNION
    SELECT
osm_id,
'way' AS osm_type,
           concat('https://osm.org/way/', osm_id) AS url,
           concat('w', osm_id) AS josmuid,
           "addr:housenumber",
"addr:housename",
"addr:street",
           "ref:caclr",
"note:caclr"
    FROM planet_osm_polygon
    WHERE "addr:street" IS NOT NULL
)

SELECT
osm_id,
       osm_type,
       url,
       josmuid,
       "addr:street",
       "ref:caclr",
       "note:caclr"
FROM osm_potential_addresses
WHERE "addr:housenumber" IS NULL AND "addr:housename" IS NULL;
