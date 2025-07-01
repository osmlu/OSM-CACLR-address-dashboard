-- Title: Most probably incorrect missing ref
-- Description: Objects tagged ref:caclr=missing but overlapping a CACLR address where the housenumber and street match
-- include osm_potential_addresses_withgeom.sql

-- 8< cut here >8 --

SELECT
         osm.osm_id,
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
         caclr.id_caclr_bat
FROM osm_potential_addresses AS osm,
         addresses AS caclr
WHERE osm."ref:caclr" LIKE 'missing'
AND osm.way && caclr.geom_3857
AND st_intersects(osm.way, caclr.geom_3857)
AND osm."addr:housenumber" = caclr.numero::text
AND osm."addr:street" = caclr.rue
ORDER BY localite, rue, numero;
