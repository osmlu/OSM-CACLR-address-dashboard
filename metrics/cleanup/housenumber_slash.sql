-- Title: Slash in housenumbers
-- Description: Housenumbers containing slashes
-- include osm_potential_addresses.sql
SELECT osm_id, osm_type, "addr:housenumber", "addr:street", "addr:city"
FROM osm_potential_addresses
WHERE "addr:housenumber" ~ '/';
