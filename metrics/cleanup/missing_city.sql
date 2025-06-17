-- Title: Missing city
-- Description: OSM addresses lacking a city tag
SELECT osm_id, 'node' AS osm_type, "addr:housenumber", "addr:street"
FROM planet_osm_point
WHERE "addr:housenumber" IS NOT NULL AND "addr:city" IS NULL
UNION
SELECT osm_id, 'way' AS osm_type, "addr:housenumber", "addr:street"
FROM planet_osm_polygon
WHERE "addr:housenumber" IS NOT NULL AND "addr:city" IS NULL;
