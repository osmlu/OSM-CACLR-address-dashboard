-- Title: Same position addresses
-- Description: Multiple addresses sharing identical coordinates
SELECT count(*) FROM (
    SELECT lat_wgs84, lon_wgs84
    FROM addresses
    GROUP BY lat_wgs84, lon_wgs84
    HAVING count(*) > 1
) AS foo;
