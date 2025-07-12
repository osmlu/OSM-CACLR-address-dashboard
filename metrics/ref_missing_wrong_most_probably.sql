-- Title: Most probably incorrect missing ref
-- Description: Objects tagged ref:caclr=missing but overlapping a CACLR address where the housenumber and street match
-- include osm_potential_addresses_withgeom.sql

-- 8< cut here >8 --

SELECT
    opa.osm_id,
    opa.osm_timestamp,
    opa.url,
    opa.josmuid,
    opa."addr:housenumber",
    caclr.numero,
    opa."addr:street",
    caclr.rue,
    opa."addr:city",
    caclr.localite,
    opa."note:caclr",
    opa.note,
    opa."ref:caclr",
    caclr.id_caclr_bat,
    i.ds_timestamp_modif
FROM osm_potential_addresses AS opa
INNER JOIN addresses AS caclr
    ON (
        opa.way && caclr.geom_3857
        AND st_intersects(opa.way, caclr.geom_3857)
    )
LEFT JOIN immeuble AS i
    ON caclr.id_caclr_bat = i.numero_interne::text
WHERE
    opa."ref:caclr" LIKE 'missing'
    AND opa."addr:housenumber" = caclr.numero::text
    AND opa."addr:street" = caclr.rue
ORDER BY
    caclr.localite,
    caclr.rue,
    caclr.numero;
