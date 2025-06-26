-- Title: addr:interpolation ways
-- Description: Ways tagged with addr:interpolation
SELECT osm_id,
       'way' AS osm_type,
       concat('https://osm.org/way/', osm_id) AS url,
       concat('w', osm_id) AS josmuid,
       "addr:interpolation",
       "ref:caclr",
       "note:caclr"
FROM planet_osm_line
WHERE "addr:interpolation" IS NOT NULL;
