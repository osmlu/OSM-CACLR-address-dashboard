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
    opa."note:caclr",
    i.date_fin_valid,
    i.ds_timestamp_modif,
    opa.osm_timestamp
FROM osm_potential_addresses AS opa
LEFT JOIN addresses AS a
    ON opa."ref:caclr" = a.id_caclr_bat
LEFT JOIN immeuble AS i
    ON opa."ref:caclr" = i.numero_interne::text
WHERE
    a.id_caclr_bat IS NULL
    AND opa."ref:caclr" NOT IN ('missing', 'wrong')
ORDER BY
    opa."addr:city",
    opa."addr:street",
    opa."addr:housenumber";
