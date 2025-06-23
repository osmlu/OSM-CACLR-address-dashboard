-- Title: addr:interpolation ways
-- Description: Ways tagged with addr:interpolation
SELECT osm_id, 'way' AS osm_type, "addr:interpolation"
FROM planet_osm_line
WHERE "addr:interpolation" IS NOT NULL;
