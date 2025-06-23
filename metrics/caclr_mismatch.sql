-- Title: CACLR mismatch
-- Description: Addresses tagged with ref:caclr where the street or city differs from the official record
-- include osm_potential_addresses.sql
SELECT count(*) FROM osm_potential_addresses, addresses
WHERE osm_potential_addresses."ref:caclr" = addresses.id_caclr_bat
  AND (osm_potential_addresses."addr:street" != addresses.rue
    OR osm_potential_addresses."addr:city" != addresses.localite);
