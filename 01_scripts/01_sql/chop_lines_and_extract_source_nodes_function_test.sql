---------------------------------------------------------------------------
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
    
-----------------------------------------------------------------------------------------------------------------    
/* this expression creates edge segments from the chopped nodes, extending it by ~10 meters in both directions */
,   way_segment_array as (
    select
        array[ 
            geohash_decode(st_geohash(from_node,10))
        ,   geohash_decode(st_geohash(to_node,10))
        ] as nodes
    ,   edge_geom
    from
----------------------------------------------
/* this subselect creates the extended edge */ 
        (select
            ST_MakeLine(
                st_translate(from_node, sin(az1) * len, cos(az1) * len)
            ,   st_translate(to_node, sin(az2) * len, cos(az2) * len)
            ) as edge_geom
        ,   from_node
        ,   to_node
        from 
------------------------------------------------------------------------------------------------------------
/* this subselect creates the from_node and the to_node and calculates the azimuth angles between these two.
 * Distance, extension factor and azimuth yield the input for the st_translate in the superset query.
 */
            (select
                 lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index) as from_node
             ,   this_node_geom as to_node
             ,   st_azimuth(lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index),this_node_geom) as az1
             ,   st_azimuth(this_node_geom,lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index)) as az2
             ,   ST_Distance(lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index),this_node_geom) + 0.0001 as len
             from
                input
            ) input 
        ) way_segment        
    where
        way_segment.from_node is not null
    )

----------------------------------------------------
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
    
----------------------------------------------------------------------------------------------------------------------
/* this expression calculates the azimuth between the streetside nodes and the edge its source source edge segments */
,   azimuth as (
    select
       st_azimuth(sides.child_node,st_closestpoint(sides.child_node,way_segment_array.edge_geom)) as azimuth
    from
        (select
            source_node_id
        ,   (st_dump(sides.source_node_buffer_splits)).geom as child_node
        from
            sides
        ) sides
    left join
        way_segment_array way_segment_array
    on 
        sides.source_node_id = any (way_segment_array.nodes)
    )
    
-------------------------------------------------------------------------------------------------------------------------------
/* this expression creates the street sides from grouping by azimuth and limiting pairing to closest distance between points */


/* this expression creates the bridges from splitting the child_node_hulls */

    
/* the select inserts the edges into the edges table */
select
--    azimuth.*
--    sides.*
    way_segment_array.*
--,   source_node_id
--,   source_node_index
--,   (st_dump(source_node_buffer_splits)).geom
--,   unnest(source_node_buffer_splits)
--,   sum(cardinality(output.source_node_buffer_splits))
from
--    azimuth azimuth
--    sides sides
    way_segment_array way_segment_array
    

-- order by
--     nodes
    
