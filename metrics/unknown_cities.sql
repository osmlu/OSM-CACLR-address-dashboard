-- Title: Unknown cities
-- Description: OSM addresses with a city not present in CACLR
-- include osm_potential_addresses.sql
SELECT osm_id, osm_type, "addr:housenumber", "addr:street", "addr:city"
FROM osm_potential_addresses
WHERE "addr:city" NOT IN (SELECT localite FROM addresses);
