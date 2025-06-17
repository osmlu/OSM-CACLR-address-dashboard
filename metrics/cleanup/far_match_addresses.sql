-- Title: Far matches
-- Description: OSM addresses matching CACLR but located more than 30m away
-- include osm_potential_addresses.sql
select * from (SELECT   osm.*, 
         caclr.id_caclr_bat, 
         St_distance(St_centroid(osm.way), St_transform(caclr.geom, 3857)) AS dist,
         St_transform(caclr.geom, 3857) AS caclr_geom,
         St_astext(St_shortestline(St_centroid(osm.way), St_transform(caclr.geom, 3857))) as line
FROM     osm_potential_addresses osm, 
         addresses caclr 
WHERE    osm."ref:caclr" IS NULL 
AND      osm."addr:housenumber" = caclr.numero 
AND      osm."addr:city" = caclr.localite 
AND      osm."addr:postcode" = caclr.code_postal::text 
AND      osm."addr:street" = caclr.rue 
ORDER BY dist DESC) as foo where dist > 30;
