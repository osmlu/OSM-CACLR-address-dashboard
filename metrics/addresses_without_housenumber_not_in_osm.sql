-- Title: Missing number not in OSM
-- Description: Addresses without a housenumber that also do not exist in OSM
-- include osm_potential_addresses.sql
SELECT addresses.*
FROM addresses
LEFT JOIN
    osm_potential_addresses
    ON addresses.id_caclr_bat = osm_potential_addresses."ref:caclr"
WHERE addresses.numero IS NULL
  AND osm_potential_addresses.osm_id IS NULL
  AND addresses.localite NOT IN ('Luxembourg')
ORDER BY addresses.localite, addresses.rue;
