-- Title: Far matches
-- Description: OSM addresses matching CACLR but located more than 30m away
-- include osm_potential_addresses.sql

-- 8< cut here >8 --

SELECT * FROM (SELECT
osm.*,
         caclr.id_caclr_bat,
         st_distance(
             st_transform(st_centroid(osm.way), 2169),
             st_transform(caclr.geom, 2169)
         ) AS dist,
         st_transform(caclr.geom, 2169) AS caclr_geom,
         st_astext(
             st_shortestline(
                 st_transform(st_centroid(osm.way), 2169),
                 st_transform(caclr.geom, 2169)
             )
         ) AS line
FROM osm_potential_addresses AS osm,
         addresses AS caclr
WHERE osm."ref:caclr" IS NULL
AND osm."addr:housenumber" = caclr.numero
AND osm."addr:city" = caclr.localite
AND osm."addr:postcode" = caclr.code_postal::text
AND osm."addr:street" = caclr.rue
ORDER BY dist DESC) AS foo
WHERE dist > 30;
