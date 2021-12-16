/*

Create a vertex and edge topology from input linestrings while preserving
all attribute data from the original linestring on the split segments.

*/

WITH segments AS (
    SELECT 
        way_id
    ,   properties
    ,   ST_AsText(ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY way_id ORDER BY way_id, (pt).path), (pt).geom))::geometry AS geom
    FROM 
        (SELECT 
             way_id
         ,   json_build_object(
             'highways'
             ,   json_build_object(
                     'way_id'
                 ,   way_id
                 ,   'length'
				 ,   round(st_length(geom::geography)::numeric,2)
                 ,   'type'
                 ,   type
                 ,   'surface'
                 ,   surface
                 ,   'name'
                 ,   name                 )
             ) as properties
         ,   ST_DumpPoints(clipped_geom) AS pt 
    from 
        (select 
            roads.*
        ,   (ST_Dump(ST_Intersection(selector.geom, roads.geom))).geom clipped_geom
        from 
            (select geom from osm.boundaries where area_id = -180627) as selector
        inner join 
            osm.highways roads on ST_Intersects(selector.geom, roads.geom)
         ) as clipped
    where ST_Dimension(clipped.clipped_geom) = 1
         ) as dumps
    )
SELECT 
    row_number() over(order by way_id) as edge_id_input
,   geohash_decode(st_geohash(ST_pointn(geom, 1),10)) as from_node
,   geohash_decode(st_geohash(ST_pointn(geom, 2),10)) as to_node
,   round(st_length(geom::geography)::numeric,2) as length
,   a.* as edges 
FROM 
    segments a 
WHERE 
    geom IS NOT NULL 
order by way_id

-- code for the sub query clipping taken from the documentation here: https://postgis.net/docs/ST_Intersection.html (see section "examples")