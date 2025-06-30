-- Title: Missing CACLR reference
-- Description: ref:caclr values present in OSM but not in the official dataset
-- include osm_potential_addresses.sql
SELECT
    opa.osm_id,
    opa.osm_type,
    opa.url,
    opa.josmuid,
    opa."addr:housenumber",
    opa."addr:street",
    opa."addr:postcode",
    opa."addr:city",
    opa."ref:caclr",
    opa."note:caclr"
FROM osm_potential_addresses AS opa
LEFT JOIN addresses AS a
  ON a.id_caclr_bat = opa."ref:caclr"
WHERE a.id_caclr_bat IS NULL
ORDER BY
    opa."addr:city",
    opa."addr:street",
    opa."addr:housenumber";
