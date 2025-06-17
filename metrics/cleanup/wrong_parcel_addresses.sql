-- Title: Wrong parcel matches
-- Description: OSM addresses matching CACLR but placed in a different parcel
    WITH osm_potential_addresses AS (
        SELECT osm_id, osm_user, concat('https://osm.org/way/' , osm_id) as url, concat('w' , osm_id) as josmuid, osm_timestamp, name, "addr:housenumber", "addr:street", "addr:postcode", "addr:city", "addr:country", "ref:caclr", "note", "note:caclr", "fixme", way
        FROM planet_osm_polygon
        WHERE "addr:housenumber" IS NOT NULL
          AND "addr:street" IS NOT NULL
          AND "addr:postcode" IS NOT NULL
          AND "addr:city" IS NOT NULL
        UNION SELECT osm_id, osm_user,  concat('https://osm.org/node/' , osm_id) as url, concat('n' , osm_id) as josmuid, osm_timestamp, name, "addr:housenumber", "addr:street", "addr:postcode", "addr:city", "addr:country", "ref:caclr", "note", "note:caclr", "fixme", way
        FROM planet_osm_point
        WHERE "addr:housenumber" IS NOT NULL
          AND "addr:street" IS NOT NULL
          AND "addr:postcode" IS NOT NULL
          AND "addr:city" IS NOT NULL
        )

-- 8< cut here >8 --

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
