-- Title: No match in CACLR
-- Description: OSM addresses that cannot be matched to CACLR
-- include osm_potential_addresses_street.sql

SELECT
    opa.osm_id,
    opa.osm_type,
    opa.osm_timestamp,
    opa.url,
    opa.josmuid,
    opa.osm_user,
    opa."addr:housenumber" AS numero,
    opa."addr:street" AS rue,
    opa."addr:postcode" AS codepostal,
    opa."addr:city" AS localite,
    opa."ref:caclr",
    opa."note:caclr"
FROM osm_potential_addresses AS opa
LEFT JOIN
    addresses AS a
    ON
        opa."addr:housenumber" = a.numero
        AND opa."addr:city" = a.localite
        AND opa."addr:street" = a.rue
WHERE
    a.localite IS NULL
    AND opa."ref:caclr" IS NULL
    AND opa."addr:housenumber" NOT LIKE '%-%'
ORDER BY localite, rue, numero;
