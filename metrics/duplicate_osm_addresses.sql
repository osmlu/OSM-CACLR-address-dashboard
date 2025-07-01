-- Title: Duplicate OSM addresses
-- Description: Multiple OSM objects share the same housenumber, street and city
-- include osm_potential_addresses.sql
SELECT
    "addr:housenumber",
    "addr:street",
    "addr:city",
    COUNT(*) AS occurrences
FROM osm_potential_addresses
WHERE "addr:housenumber" IS NOT NULL
GROUP BY "addr:housenumber", "addr:street", "addr:city"
HAVING COUNT(*) > 1
ORDER BY
    occurrences DESC,
    "addr:city" ASC,
    "addr:street" ASC,
    "addr:housenumber" ASC;
