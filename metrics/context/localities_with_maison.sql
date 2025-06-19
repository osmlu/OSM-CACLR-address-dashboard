-- Title: Maison localities
-- Description: Context: Number of localities in CACLR containing street name 'Maison'
SELECT count(*) FROM (
    SELECT localite
    FROM addresses
    WHERE rue LIKE 'Maison'
    GROUP BY localite
) AS foo;
