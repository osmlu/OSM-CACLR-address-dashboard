-- Title: Context: Maison localities
-- Description: Context: Number of localities in CACLR with street name 'Maison'
SELECT
    localite,
    COUNT(*) AS count
FROM addresses
WHERE rue LIKE 'Maison'
GROUP BY localite
ORDER BY count DESC, localite ASC;
