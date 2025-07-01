-- Title: Unknown postcodes
-- Description: OSM addresses with a postcode not present in CACLR
-- include osm_potential_addresses.sql
SELECT
    osm_id,
    osm_type,
    url,
    josmuid,
    "addr:housenumber",
    "addr:street",
    "addr:postcode",
    "addr:city",
    "ref:caclr",
    "note:caclr"
FROM osm_potential_addresses
WHERE "addr:postcode" NOT IN (
    SELECT a.code_postal::text
    FROM addresses AS a
);
