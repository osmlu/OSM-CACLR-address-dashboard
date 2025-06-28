-- Title: No match in CACLR
-- Description: OSM addresses that cannot be matched to CACLR
WITH osm_potential_addresses AS (
    SELECT
osm_id,
'node' AS osm_type,
osm_user,
name,
           "addr:housenumber",
"addr:street",
"addr:postcode",
           "addr:city",
"ref:caclr",
"note:caclr",
way
    FROM planet_osm_point
    WHERE "addr:street" IS NOT NULL
    UNION
    SELECT
osm_id,
'way' AS osm_type,
osm_user,
name,
           "addr:housenumber",
"addr:street",
"addr:postcode",
           "addr:city",
"ref:caclr",
"note:caclr",
way
    FROM planet_osm_polygon
    WHERE "addr:street" IS NOT NULL
)

SELECT
osm_id,
osm_type,
url,
josmuid,
osm_user,
       "addr:housenumber" AS numero,
       "addr:street" AS rue,
       "addr:postcode" AS codepostal,
       "addr:city" AS localite,
       "ref:caclr",
       "note:caclr"
FROM (
    SELECT
osm_id,
osm_type,
osm_user,
name,
"addr:housenumber",
           "addr:street",
           "addr:postcode",
           "addr:city",
           "ref:caclr",
           "note:caclr",
           concat(
               'https://osm.org/',
               CASE WHEN osm_type = 'node' THEN 'node/' ELSE 'way/' END,
               osm_id
           ) AS url,
           concat(
               CASE WHEN osm_type = 'node' THEN 'n' ELSE 'w' END, osm_id
           ) AS josmuid
    FROM osm_potential_addresses
) AS osm
LEFT JOIN
    addresses
    ON
        osm."addr:housenumber" = addresses.numero
        AND osm."addr:city" = addresses.localite
        AND osm."addr:street" = addresses.rue
WHERE
    addresses.localite IS NULL
    AND osm."ref:caclr" IS NULL
    AND osm."addr:housenumber" NOT LIKE '%-%'
ORDER BY localite, rue, numero;
