-- Title: Context: addresses agglutinated in CACLR
-- Description: Addresses go on the biggest building of the parcel. If there's more than one address on the parcel, it's a mess, unless they're aligned by hand.

SELECT
rue,
         rue,
         localite,
         code_postal,
         id_caclr_rue,
         lat_wgs84,
         lon_wgs84,
         commune,
         Count(lat_wgs84) AS count,
         String_agg(numero, ',' ORDER BY numero) AS numero,
         String_agg(
             id_caclr_bat::text, ';' ORDER BY id_caclr_bat
         ) AS id_caclr_bat
FROM addresses
GROUP BY rue,
         code_postal,
         id_caclr_rue,
         lat_wgs84,
         lon_wgs84,
         commune,
         localite,
         rue
HAVING Count(lat_wgs84) > 1
