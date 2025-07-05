-- Title: CACLR mismatch
-- Description: Addresses tagged with ref:caclr where the street or city differs from the official record
-- include osm_potential_addresses.sql
SELECT
    opa.osm_id,
    opa.osm_type,
    opa.url,
    opa.josmuid,
    opa."addr:housenumber",
    opa."addr:street" AS osm_street,
    a.rue AS caclr_street,
    opa."addr:city" AS osm_city,
    a.localite AS caclr_city,
    opa."ref:caclr",
    opa."note:caclr",
    i.ds_timestamp_modif,
    opa.osm_timestamp
FROM osm_potential_addresses AS opa
INNER JOIN addresses AS a
    ON opa."ref:caclr" = a.id_caclr_bat
LEFT JOIN immeuble AS i
    ON opa."ref:caclr" = i.numero_interne
WHERE
    opa."addr:street" != a.rue
    OR opa."addr:city" != a.localite
ORDER BY
    a.localite,
    a.rue,
    opa."addr:housenumber";
