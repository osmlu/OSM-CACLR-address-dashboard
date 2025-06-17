WITH osm_potential_addresses AS (
    SELECT osm_id, 'node' AS osm_type,
           "addr:housenumber", "addr:street", "addr:postcode",
           "addr:city", "ref:caclr"
    FROM planet_osm_point
    WHERE "addr:housenumber" IS NOT NULL
      AND "addr:street" IS NOT NULL
      AND "addr:postcode" IS NOT NULL
      AND "addr:city" IS NOT NULL
    UNION
    SELECT osm_id, 'way' AS osm_type,
           "addr:housenumber", "addr:street", "addr:postcode",
           "addr:city", "ref:caclr"
    FROM planet_osm_polygon
    WHERE "addr:housenumber" IS NOT NULL
      AND "addr:street" IS NOT NULL
      AND "addr:postcode" IS NOT NULL
      AND "addr:city" IS NOT NULL
)
