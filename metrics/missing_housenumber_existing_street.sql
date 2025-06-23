-- Title: Missing number on existing street
-- Description: Addresses without number where the street also has numbered entries
select * from addresses as ass
where numero is null
and exists(select rue from addresses where numero is not null and id_caclr_rue = ass.id_caclr_rue);
