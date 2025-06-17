-- Title: Mixed Maison localities
-- Description: Localities containing both 'Maison' and regular street addresses
WITH maison AS (
    SELECT count(numero) AS numeromaison, localite
    FROM addresses
    WHERE rue LIKE 'Maison'
    GROUP BY localite
),
nomaison AS (
    SELECT count(numero) AS numeronomaison, localite
    FROM addresses
    WHERE rue NOT LIKE 'Maison'
    GROUP BY localite
)
SELECT count(*) FROM maison, nomaison
WHERE maison.localite = nomaison.localite;
