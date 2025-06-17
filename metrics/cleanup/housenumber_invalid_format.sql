-- Title: Invalid housenumber format
-- Description: OSM housenumbers not matching the expected pattern
WITH osm_potential_addresses AS (
    SELECT osm_id, 'node' AS osm_type,
           "addr:housenumber", "addr:street", "addr:postcode",
           "addr:city"
    FROM planet_osm_point
    WHERE "addr:housenumber" IS NOT NULL
    UNION
    SELECT osm_id, 'way' AS osm_type,
           "addr:housenumber", "addr:street", "addr:postcode",
           "addr:city"
    FROM planet_osm_polygon
    WHERE "addr:housenumber" IS NOT NULL
)
SELECT osm_id, osm_type, "addr:housenumber", "addr:street", "addr:city"
FROM osm_potential_addresses
WHERE "addr:housenumber" !~ '^[1-9][0-9]{0,2}[A-Z]{0,3}(-*[1-9][0-9]{0,2}[A-Z]{0,3}){0,4}$';
