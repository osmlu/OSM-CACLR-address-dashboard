WITH osm_potential_addresses AS (
    SELECT osm_id,
           'node' AS osm_type,
           osm_user,
           concat('https://osm.org/node/', osm_id) AS url,
           concat('n', osm_id) AS josmuid,
           osm_timestamp,
           name,
           "addr:housenumber",
           "addr:housename",
           "addr:street",
           "addr:postcode",
           "addr:city",
           "addr:country",
           "ref:caclr",
           note,
           "note:caclr",
           fixme
    FROM planet_osm_point
    WHERE "addr:housenumber" IS NOT NULL
      AND "addr:street" IS NOT NULL
      AND "addr:postcode" IS NOT NULL
      AND "addr:city" IS NOT NULL
    UNION
    SELECT osm_id,
           'way' AS osm_type,
           osm_user,
           concat('https://osm.org/way/', osm_id) AS url,
           concat('w', osm_id) AS josmuid,
           osm_timestamp,
           name,
           "addr:housenumber",
           "addr:housename",
           "addr:street",
           "addr:postcode",
           "addr:city",
           "addr:country",
           "ref:caclr",
           note,
           "note:caclr",
           fixme
    FROM planet_osm_polygon
    WHERE "addr:housenumber" IS NOT NULL
      AND "addr:street" IS NOT NULL
      AND "addr:postcode" IS NOT NULL
      AND "addr:city" IS NOT NULL
)
