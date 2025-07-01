-- Title: Context: Missing number on existing street
-- Description: Addresses without house number in CACLR where the street also has numbered entries
SELECT
    ass.id_caclr_bat,
    ass.rue,
    ass.localite
FROM addresses AS ass
WHERE
    ass.numero IS NULL
    AND EXISTS (
        SELECT 1
        FROM addresses AS b
        WHERE
            b.numero IS NOT NULL
            AND b.id_caclr_rue = ass.id_caclr_rue
    );
