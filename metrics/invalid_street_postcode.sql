-- Title: Invalid street/postcode
-- Description: Street and postcode pairs that do not exist in CACLR
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
WHERE ("addr:street", "addr:postcode") NOT IN (
    SELECT
        a.rue,
        a.code_postal::text
    FROM addresses AS a
);
