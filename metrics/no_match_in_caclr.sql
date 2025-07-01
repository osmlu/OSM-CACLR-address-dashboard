-- Title: No match in CACLR
-- Description: OSM addresses that cannot be matched to CACLR
-- include osm_potential_addresses_street.sql

SELECT
    osm.osm_id,
    osm.osm_type,
    osm.url,
    osm.josmuid,
    osm.osm_user,
    osm."addr:housenumber" AS numero,
    osm."addr:street" AS rue,
    osm."addr:postcode" AS codepostal,
    osm."addr:city" AS localite,
    osm."ref:caclr",
    osm."note:caclr"
FROM osm_potential_addresses AS osm
LEFT JOIN
    addresses AS a
    ON
        osm."addr:housenumber" = a.numero
        AND osm."addr:city" = a.localite
        AND osm."addr:street" = a.rue
WHERE
    a.localite IS NULL
    AND osm."ref:caclr" IS NULL
    AND osm."addr:housenumber" NOT LIKE '%-%'
ORDER BY localite, rue, numero;
