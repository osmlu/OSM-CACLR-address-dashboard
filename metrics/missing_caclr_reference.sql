-- Title: Missing CACLR reference
-- Description: ref:caclr values present in OSM but not in the official dataset
-- include osm_potential_addresses.sql
SELECT osm_id,
       osm_type,
       url,
       josmuid,
       "addr:housenumber",
       "addr:street",
       "addr:postcode",
       "addr:city",
       "ref:caclr",
       "note:caclr"
FROM osm_potential_addresses
WHERE "ref:caclr" NOT IN ('missing', 'wrong')
  AND "ref:caclr" NOT IN (SELECT id_caclr_bat FROM addresses)
ORDER BY "addr:city", "addr:street", "addr:housenumber";
