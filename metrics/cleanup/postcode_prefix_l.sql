-- Title: Postcodes with L prefix
-- Description: Addresses with postcode starting with L or L-
-- include osm_potential_addresses.sql
SELECT osm_id, osm_type, "addr:postcode" FROM osm_potential_addresses
WHERE "addr:postcode" ILIKE 'L%' OR "addr:postcode" ILIKE 'L-%';
