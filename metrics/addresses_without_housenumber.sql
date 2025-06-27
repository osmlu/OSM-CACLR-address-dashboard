-- Title: Context: Addresses without housenumber
-- Description: Entries in the CACLR dataset that have no house number
select * from addresses where numero is null;
