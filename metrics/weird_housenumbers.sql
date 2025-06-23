-- Title: Weird house numbers
-- Description: Addresses with numbers like 37AA or 1BIS
select numero, rue, localite from addresses where numero ~ '[A-Z]{2}';
