-- Title: Context: Housename only streets
-- Description: Streets in CACLR that only have addresses without numbers
select *
from addresses as ass
where numero is null and not exists (
    select rue from addresses
    where numero is not null and id_caclr_rue = ass.id_caclr_rue
);
