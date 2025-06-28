-- Title: Duplicate OSM addresses
-- Description: Multiple OSM objects share the same housenumber, street and city
-- include osm_potential_addresses.sql
select
"addr:housenumber",
"addr:street",
"addr:city",
count(*)
from osm_potential_addresses
where "addr:housenumber" is not null
group by "addr:housenumber", "addr:street", "addr:city"
having count(*) > 1
order by count desc, "addr:city" asc, "addr:street" asc, "addr:housenumber" asc;
