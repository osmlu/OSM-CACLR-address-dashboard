-- Title: Possibly incorrect missing ref
-- Description: Objects tagged ref:caclr=missing but overlapping a CACLR address
-- include osm_potential_addresses.sql
SELECT
         osm.osm_id,
         osm.osm_type,
         concat('https://osm.org/',
                CASE WHEN osm.osm_type='node' THEN 'node/' ELSE 'way/' END,
                osm.osm_id) AS url,
         osm_user,
         osm."addr:housenumber",
         caclr.numero,
         osm."addr:street",
         caclr.rue,
         osm."addr:city",
         caclr.localite,
         osm."note:caclr",
         osm."note", 
         caclr.id_caclr_bat
FROM     osm_potential_addresses osm, 
         addresses caclr
WHERE    osm."ref:caclr" like 'missing' 
AND      st_intersects(osm.way, St_transform(caclr.geom, 3857))
order by localite, rue, numero;
