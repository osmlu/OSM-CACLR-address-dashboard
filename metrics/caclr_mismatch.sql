-- Title: CACLR mismatch
-- Description: Addresses tagged with ref:caclr where the street or city differs from the official record
-- include osm_potential_addresses.sql
SELECT
    osm_id,
    osm_type,
    url,
    josmuid,
    osm_potential_addresses."addr:housenumber",
    osm_potential_addresses."addr:street" AS osm_street,
    addresses.rue AS caclr_street,
    osm_potential_addresses."addr:city" AS osm_city,
    addresses.localite AS caclr_city,
    osm_potential_addresses."ref:caclr",
    osm_potential_addresses."note:caclr"
FROM osm_potential_addresses
INNER JOIN
    addresses
    ON osm_potential_addresses."ref:caclr" = addresses.id_caclr_bat
WHERE osm_potential_addresses."addr:street" != addresses.rue
   OR osm_potential_addresses."addr:city" != addresses.localite
ORDER BY addresses.localite, addresses.rue,
         osm_potential_addresses."addr:housenumber";
