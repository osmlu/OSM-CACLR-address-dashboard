-- Title: Possibly incorrect missing ref
-- Description: Objects tagged ref:caclr=missing but overlapping a CACLR address
-- include osm_potential_addresses_withgeom.sql

-- 8< cut here >8 --

SELECT
    osm.osm_id,
    osm.osm_timestamp,
    osm.url,
    osm.josmuid,
    osm."addr:housenumber",
    caclr.numero,
    osm."addr:street",
    caclr.rue,
    osm."addr:city",
    caclr.localite,
    osm."note:caclr",
    osm.note,
    osm."ref:caclr",
    caclr.id_caclr_bat,
    i.ds_timestamp_modif
FROM osm_potential_addresses AS osm
INNER JOIN addresses AS caclr
    ON (
        osm.way && caclr.geom_3857
        AND st_intersects(osm.way, caclr.geom_3857)
    )
LEFT JOIN immeuble AS i
    ON caclr.id_caclr_bat = i.numero_interne
WHERE
    osm."ref:caclr" LIKE 'missing'
ORDER BY
    caclr.localite,
    caclr.rue,
    caclr.numero;
