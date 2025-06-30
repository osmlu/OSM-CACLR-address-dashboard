-- Title: Wrong parcel matches
-- Description: OSM addresses matching CACLR but placed in a different parcel
-- include osm_potential_addresses_withgeom.sql

-- 8< cut here >8 --

SELECT * FROM (SELECT
         osm.*,
         caclr.*,
         parcelles.*,
         caclr.id_caclr_bat,
         round(
             st_distance(st_centroid(osm.way), caclr.geom_3857)
         ) AS dist,
         st_astext(
             st_shortestline(
                 st_centroid(osm.way), caclr.geom_3857
             )
         ) AS line
FROM osm_potential_addresses AS osm,
         addresses AS caclr,
         parcelles
WHERE osm."ref:caclr" IS NULL
AND osm."addr:housenumber" = caclr.numero
AND osm."addr:city" = caclr.localite
AND osm."addr:postcode" = caclr.code_postal::text
AND osm."addr:street" = caclr.rue
AND caclr.id_parcelle = parcelles.id_parcell
AND NOT st_intersects(osm.way, parcelles.wkb_geometry)
ORDER BY dist DESC) AS foo
WHERE dist > 10;
