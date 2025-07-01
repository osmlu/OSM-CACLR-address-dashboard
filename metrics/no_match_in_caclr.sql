-- Title: No match in CACLR
-- Description: OSM addresses that cannot be matched to CACLR
-- include osm_potential_addresses_street.sql

SELECT
    osm_id,
    osm_type,
    url,
    josmuid,
    osm_user,
    "addr:housenumber" AS numero,
    "addr:street" AS rue,
    "addr:postcode" AS codepostal,
    "addr:city" AS localite,
    "ref:caclr",
    "note:caclr"
FROM osm_potential_addresses AS osm
LEFT JOIN
    addresses
    ON
        osm."addr:housenumber" = addresses.numero
        AND osm."addr:city" = addresses.localite
        AND osm."addr:street" = addresses.rue
WHERE
    addresses.localite IS NULL
    AND osm."ref:caclr" IS NULL
    AND osm."addr:housenumber" NOT LIKE '%-%'
ORDER BY localite, rue, numero;
