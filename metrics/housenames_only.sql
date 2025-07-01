-- Title: Context: Housename only streets
-- Description: Streets in CACLR that only have addresses without numbers
SELECT
    ass.id_caclr_bat,
    ass.rue,
    ass.localite
FROM addresses AS ass
WHERE
    ass.numero IS NULL
    AND NOT EXISTS (
        SELECT 1
        FROM addresses AS b
        WHERE
            b.numero IS NOT NULL
            AND b.id_caclr_rue = ass.id_caclr_rue
    );
