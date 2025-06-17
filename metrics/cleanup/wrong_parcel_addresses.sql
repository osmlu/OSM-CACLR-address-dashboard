-- Title: Wrong parcel matches
-- Description: OSM addresses matching CACLR but placed in a different parcel
-- include osm_potential_addresses.sql
select * from (SELECT
         round(St_distance(St_centroid(osm.way), St_transform(caclr.geom, 3857))) AS dist,
         osm.*, 
         caclr.id_caclr_bat, 
         St_transform(caclr.geom, 3857) AS caclr_geom, 
         St_astext(St_shortestline(St_centroid(osm.way), St_transform(caclr.geom, 3857))) as line,
         caclr.*,
         parcelles.*
FROM     osm_potential_addresses osm, 
         addresses caclr,
         parcelles 
WHERE    osm."ref:caclr" IS NULL 
AND      osm."addr:housenumber" = caclr.numero 
AND      osm."addr:city" = caclr.localite
AND      osm."addr:postcode" = caclr.code_postal::text 
AND      osm."addr:street" = caclr.rue 
and      caclr.id_parcelle = parcelles.id_parcell
and not  st_intersects(osm.way, St_transform(parcelles.wkb_geometry, 3857))
ORDER BY dist DESC) as foo where dist > 10;
