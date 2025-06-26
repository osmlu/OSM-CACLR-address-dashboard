-- Title: Unknown cities
-- Description: OSM addresses with a city not present in CACLR
-- include osm_potential_addresses.sql
SELECT osm_id,
       osm_type,
       url,
       josmuid,
       "addr:housenumber",
       "addr:street",
       "addr:city",
       "ref:caclr",
       "note:caclr"
FROM osm_potential_addresses
WHERE "addr:city" NOT IN (SELECT localite FROM addresses);
