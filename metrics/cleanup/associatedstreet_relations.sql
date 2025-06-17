-- Title: associatedStreet relations
-- Description: Relations of type associatedStreet
SELECT id AS osm_id, 'relation' AS osm_type
FROM planet_osm_rels
WHERE tags->'type' = 'associatedStreet';
