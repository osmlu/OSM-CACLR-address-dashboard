-- Title: Garbage house numbers
-- Description: Addresses with trailing punctuation in the house number
select
numero,
rue,
localite
from addresses
where numero ~ '\\.$';
