-- Title: Context: Addresses present more than once in CACLR
-- Description: Context: Addresses in CACLR sharing the same id_caclr_bat value, e.g. when a parcel got split and both parts get the old address
SELECT
    id_caclr_bat,
    numero,
    rue,
    localite,
    COUNT(*) AS occurrences
FROM addresses
GROUP BY id_caclr_bat, numero, rue, localite
HAVING COUNT(id_caclr_bat) > 1
ORDER BY occurrences DESC, id_caclr_bat ASC;
