-- Title: Unknown streets
-- Description: OSM addresses referencing a street not present in CACLR
-- include osm_potential_addresses.sql
SELECT osm_id, osm_type, "addr:housenumber", "addr:street", "addr:city"
FROM osm_potential_addresses
WHERE "addr:street" NOT IN (SELECT rue FROM addresses)
ORDER BY "addr:street";
