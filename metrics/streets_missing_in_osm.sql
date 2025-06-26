-- Title: Streets missing in OSM
-- Description: Street names present in CACLR but absent from OSM
SELECT rue AS street,
       COUNT(*) AS address_count
FROM addresses
WHERE rue NOT IN (
    SELECT DISTINCT "addr:street" FROM planet_osm_point WHERE "addr:street" IS NOT NULL
    UNION
    SELECT DISTINCT "addr:street" FROM planet_osm_polygon WHERE "addr:street" IS NOT NULL
    UNION
    SELECT DISTINCT name FROM planet_osm_line WHERE name IS NOT NULL
)
GROUP BY rue
ORDER BY rue;
