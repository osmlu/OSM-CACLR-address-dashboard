-- Title: Context: Mixed Maison localities
-- Description: Localities in CACLR containing both 'Maison' and regular street addresses
WITH maison AS (
    SELECT
        localite,
        count(numero) AS numeromaison
    FROM addresses
    WHERE rue LIKE 'Maison'
    GROUP BY localite
),

nomaison AS (
    SELECT
        localite,
        count(numero) AS numeronomaison
    FROM addresses
    WHERE rue NOT LIKE 'Maison'
    GROUP BY localite
)

SELECT maison.localite
FROM maison
INNER JOIN nomaison ON maison.localite = nomaison.localite
ORDER BY maison.localite;
