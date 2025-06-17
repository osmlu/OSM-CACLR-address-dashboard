-- Title: Maison localities
-- Description: Number of localities where street name is 'Maison'
SELECT count(*) FROM (
    SELECT localite
    FROM addresses
    WHERE rue LIKE 'Maison'
    GROUP BY localite
) AS foo;
