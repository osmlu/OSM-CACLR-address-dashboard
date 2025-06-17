-- Title: Addressed open ways
-- Description: Ways with address tags that are not closed
SELECT osm_id, 'way' AS osm_type, "addr:housenumber", "addr:street"
FROM planet_osm_line
WHERE ("addr:housenumber" IS NOT NULL OR "addr:street" IS NOT NULL OR
       "addr:city" IS NOT NULL OR "addr:postcode" IS NOT NULL)
  AND NOT ST_IsClosed(way);
