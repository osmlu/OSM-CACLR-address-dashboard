-- Title: Context: Addresses without housenumber
-- Description: Entries in the CACLR dataset that have no house number
SELECT
    id_caclr_bat,
    rue,
    localite
FROM addresses
WHERE numero IS NULL;
