-- Title: Duplicate CACLR IDs
-- Description: Context: Addresses in CACLR sharing the same id_caclr_bat value
SELECT count(*) FROM (
    SELECT id_caclr_bat
    FROM addresses
    GROUP BY id_caclr_bat, numero, rue, localite
    HAVING count(id_caclr_bat) > 1
) AS foo;
