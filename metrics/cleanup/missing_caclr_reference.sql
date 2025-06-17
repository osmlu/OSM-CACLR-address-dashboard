-- Title: Missing CACLR reference
-- Description: ref:caclr values present in OSM but not in the official dataset
-- include osm_potential_addresses.sql
SELECT count(*) FROM (
    SELECT DISTINCT "ref:caclr" FROM osm_potential_addresses
    WHERE "ref:caclr" NOT IN ('missing', 'wrong')
    EXCEPT
    SELECT id_caclr_bat FROM addresses
) AS foo;
