-- Title: Streets missing in OSM
-- Description: Street names present in CACLR but absent from OSM
SELECT
    rue AS street,
    COUNT(*) AS address_count
FROM addresses
WHERE
    rue NOT IN (
        SELECT DISTINCT p."addr:street"
        FROM planet_osm_point AS p
        WHERE p."addr:street" IS NOT NULL
        UNION
        SELECT DISTINCT poly."addr:street"
        FROM planet_osm_polygon AS poly
        WHERE poly."addr:street" IS NOT NULL
        UNION
        SELECT DISTINCT l.name
        FROM planet_osm_line AS l
        WHERE l.name IS NOT NULL
    )
GROUP BY rue
ORDER BY rue;
