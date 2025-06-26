-- Title: Far matches
-- Description: OSM addresses matching CACLR but located more than 30m away
    WITH osm_potential_addresses AS (
        SELECT osm_id, 'way' AS osm_type, osm_user, concat('https://osm.org/way/' , osm_id) as url, concat('w' , osm_id) as josmuid, osm_timestamp, name, "addr:housenumber", "addr:street", "addr:postcode", "addr:city", "addr:country", "ref:caclr", "note", "note:caclr", "fixme", way
        FROM planet_osm_polygon
        WHERE "addr:housenumber" IS NOT NULL
          AND "addr:street" IS NOT NULL
          AND "addr:postcode" IS NOT NULL
          AND "addr:city" IS NOT NULL
        UNION SELECT osm_id, 'node' AS osm_type, osm_user,  concat('https://osm.org/node/' , osm_id) as url, concat('n' , osm_id) as josmuid, osm_timestamp, name, "addr:housenumber", "addr:street", "addr:postcode", "addr:city", "addr:country", "ref:caclr", "note", "note:caclr", "fixme", way
        FROM planet_osm_point
        WHERE "addr:housenumber" IS NOT NULL
          AND "addr:street" IS NOT NULL
          AND "addr:postcode" IS NOT NULL
          AND "addr:city" IS NOT NULL
        )

-- 8< cut here >8 --

select * from (SELECT   osm.*,
         caclr.id_caclr_bat,
         St_distance(St_transform(St_centroid(osm.way), 2169), St_transform(caclr.geom, 2169)) AS dist,
         St_transform(caclr.geom, 2169) AS caclr_geom,
         St_astext(St_shortestline(St_transform(St_centroid(osm.way), 2169), St_transform(caclr.geom, 2169))) as line
FROM     osm_potential_addresses osm,
         addresses caclr
WHERE    osm."ref:caclr" IS NULL
AND      osm."addr:housenumber" = caclr.numero
AND      osm."addr:city" = caclr.localite
AND      osm."addr:postcode" = caclr.code_postal::text
AND      osm."addr:street" = caclr.rue
ORDER BY dist DESC) as foo where dist > 30;
