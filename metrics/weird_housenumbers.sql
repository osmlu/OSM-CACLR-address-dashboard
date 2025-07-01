-- Title: Context: Weird house numbers
-- Description: Addresses with numbers like 37AA or 1BIS. We import them as is, but should be aware of them.
select
    numero,
    rue,
    localite
from addresses
where numero ~ '[A-Z]{2}';
