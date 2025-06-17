-- Title: Unknown postcodes
-- Description: OSM addresses with a postcode not present in CACLR
-- include osm_potential_addresses.sql
SELECT osm_id, osm_type, "addr:housenumber", "addr:street", "addr:postcode", "addr:city"
FROM osm_potential_addresses
WHERE "addr:postcode" NOT IN (SELECT code_postal::text FROM addresses);
