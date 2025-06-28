-- Title: Wrong parcel matches
-- Description: OSM addresses matching CACLR but placed in a different parcel
    WITH osm_potential_addresses AS (
        SELECT
            osm_id,
'way' AS osm_type,
osm_user,
concat('https://osm.org/way/', osm_id) AS url,
concat('w', osm_id) AS josmuid,
osm_timestamp,
name,
"addr:housenumber",
"addr:street",
"addr:postcode",
"addr:city",
"addr:country",
"ref:caclr",
note,
"note:caclr",
fixme,
way
        FROM planet_osm_polygon
        WHERE "addr:housenumber" IS NOT NULL
          AND "addr:street" IS NOT NULL
          AND "addr:postcode" IS NOT NULL
          AND "addr:city" IS NOT NULL
        UNION
        SELECT
osm_id,
'node' AS osm_type,
osm_user,
concat('https://osm.org/node/', osm_id) AS url,
concat('n', osm_id) AS josmuid,
osm_timestamp,
name,
"addr:housenumber",
"addr:street",
"addr:postcode",
"addr:city",
"addr:country",
"ref:caclr",
note,
"note:caclr",
fixme,
way
        FROM planet_osm_point
        WHERE "addr:housenumber" IS NOT NULL
          AND "addr:street" IS NOT NULL
          AND "addr:postcode" IS NOT NULL
          AND "addr:city" IS NOT NULL
        )

-- 8< cut here >8 --

SELECT * FROM (SELECT
         osm.*,
         caclr.*,
         parcelles.*,
         caclr.id_caclr_bat,
         round(
             st_distance(st_centroid(osm.way), st_transform(caclr.geom, 3857))
         ) AS dist,
         st_transform(caclr.geom, 3857) AS caclr_geom,
         st_astext(
             st_shortestline(
                 st_centroid(osm.way), st_transform(caclr.geom, 3857)
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
AND NOT st_intersects(osm.way, st_transform(parcelles.wkb_geometry, 3857))
ORDER BY dist DESC) AS foo
WHERE dist > 10;
