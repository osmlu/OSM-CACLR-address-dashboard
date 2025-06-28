-- Title: Lowercase housenumbers
-- Description: Housenumbers containing lowercase letters
-- include osm_potential_addresses.sql
SELECT
osm_id,
       osm_type,
       url,
       josmuid,
       "addr:housenumber",
       "addr:street",
       "addr:city",
       "ref:caclr",
       "note:caclr"
FROM osm_potential_addresses
WHERE "addr:housenumber" ~ '[a-z]';
