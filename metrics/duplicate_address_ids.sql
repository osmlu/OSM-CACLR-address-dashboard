-- Title: Duplicate CACLR IDs
-- Description: Context: Addresses in CACLR sharing the same id_caclr_bat value, e.g. when a parcel got split and both parts get the old address
SELECT count(*) FROM (
    SELECT id_caclr_bat
    FROM addresses
    GROUP BY id_caclr_bat, numero, rue, localite
    HAVING count(id_caclr_bat) > 1
) AS foo;
