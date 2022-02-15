/* this expression chops up a road linestring into the constituent nodes */
with input as (
    select
        ((st_dumppoints(a.geom)).geom) as this_node_geom
    ,   way_id as this_way_id
    ,   unnest((st_dumppoints(a.geom)).path) as this_node_index
    from 
        (select
            way_id
        ,   geom
        from
            osm.highways_dev 
--        order by
--            random()
       limit 1
        ) a
    --limit 1
    )
    
/* this expression creates edge segments from the chopped nodes, extending it by 100 meters in both directions */
,   way_segment_array as (
    select
        array[ 
            geohash_decode(st_geohash(from_node,10))
        ,   geohash_decode(st_geohash(to_node,10))
        ] as nodes
    ,   geom
    from
        (select
            ST_MakeLine(lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index), this_node_geom) as geom
        ,   lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index) as from_node
        ,   this_node_geom as to_node
        from 
            input
        ) way_segment
----------------------------

--SELECT ST_MakeLine(ST_TRANSLATE(a, sin(az1) * len, cos(az1) * 
--len),ST_TRANSLATE(b,sin(az2) * len, cos(az2) * len))
--
--  FROM (
--    SELECT a, b, ST_Azimuth(a,b) AS az1, ST_Azimuth(b, a) AS az2, ST_Distance(a,b) + 1000 AS len
--      FROM (
--        SELECT ST_StartPoint(the_geom) AS a, ST_EndPoint(the_geom) AS b
--          FROM ST_MakeLine(ST_MakePoint(1,2), ST_MakePoint(3,4)) AS the_geom
--    ) AS sub
--) AS sub2
        
        
----------------------------
        
        
    where
        way_segment.from_node is not null
    )

/* this expression generates the streetside nodes */    
,   sides as (
    select
        output.*
    from 
        input input
    ,   osm.chop_lines_and_extract_nodes(
            input.this_way_id              
        ,   input.this_node_index         
        ,   input.this_node_geom
        ) output
    )
    
/* this expression calculates the azimuth between the streetside nodes and the edge its source source edge segments */
--,   azimuth as (
--    )
    
/* this expression creates the street sides from grouping by azimuth and limiting pairing to closest distance between points */


/* this expression creates the bridges from splitting the child_node_hulls */

    
/* the select inserts the edges into the edges table */
select
    sides.*
--,   way_segment_array.*
--,   source_node_id
--,   source_node_index
--,   (st_dump(source_node_buffer_splits)).geom
--,   unnest(source_node_buffer_splits)
--,   sum(cardinality(output.source_node_buffer_splits))
from
    sides sides
--    way_segment_array way_segment_array
    

-- order by
--     nodes
    
