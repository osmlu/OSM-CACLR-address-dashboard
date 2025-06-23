-- Title: Missing postcode
-- Description: OSM addresses with housenumber and street but no postcode
SELECT osm_id, 'node' AS osm_type, "addr:housenumber", "addr:street", "addr:city"
FROM planet_osm_point
WHERE "addr:housenumber" IS NOT NULL
  AND "addr:street" IS NOT NULL
  AND "addr:postcode" IS NULL
UNION
SELECT osm_id, 'way' AS osm_type, "addr:housenumber", "addr:street", "addr:city"
FROM planet_osm_polygon
WHERE "addr:housenumber" IS NOT NULL
  AND "addr:street" IS NOT NULL
  AND "addr:postcode" IS NULL;
