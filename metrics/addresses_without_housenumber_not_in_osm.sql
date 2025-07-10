-- Title: Missing number not in OSM
-- Description: Addresses without a housenumber that also do not exist in OSM
-- include osm_potential_addresses.sql
SELECT
    a.id_caclr_bat,
    a.rue,
    a.localite,
    i.date_debut_valid,
    i.ds_timestamp_modif,
    opa.osm_timestamp
FROM addresses AS a
LEFT JOIN osm_potential_addresses AS opa
    ON a.id_caclr_bat = opa."ref:caclr"
LEFT JOIN immeuble AS i
    ON a.id_caclr_bat = i.numero_interne::text
WHERE
    a.numero IS NULL
    AND opa.osm_id IS NULL
    AND a.localite NOT IN ('Luxembourg')
ORDER BY a.localite, a.rue;
