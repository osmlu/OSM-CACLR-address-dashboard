-- Title: Possibly incorrect missing ref
-- Description: Objects tagged ref:caclr=missing but overlapping a CACLR address

    WITH osm_potential_addresses AS (
        SELECT
            osm_id,
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
AND st_intersects(osm.way, st_transform(caclr.geom, 3857))
ORDER BY localite, rue, numero;
