-- Title: OSM objects without number or name
-- Description: Objects with addr:street but neither housenumber nor housename
-- include osm_potential_addresses_street.sql

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
