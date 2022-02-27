--CTE 0-------------------------------------------------------------------------
with way as ( 
    select
        st_snap(
            h.geom
        ,   st_union(st_closestpoint(h.geom,a.geom))
        ,   0.05
        )::geometry as geom
        ,   h.way_id
        ,   h.properties
    from 
        (select
            way_id
        ,   geom
        ,   jsonb_build_object(
                'way_id'
            ,   way_id
            ,   'name'
            ,   name
            ,   'type'
            ,   type
            ,   'surface'
            ,   surface
            ) as properties 
        from
            osm.highways h
--        order by
--            random()
        limit 30000
        ) h
        ,   (select 
                geom
            ,   addr_id
            from
                 osm.addr_combined
        ) a
        where 
            a.geom && st_buffer(h.geom, 0.000125)::geometry
        group by
            h.way_id
        ,   h.geom
        ,   h.properties
    )

--select * from way
--CTE 1-------------------------------------------------------------------------
/* this expression chops up a road linestring into the constituent nodes */
,   input as (
    select
        ((st_dumppoints(geom)).geom) as this_node_geom
    ,   way_id as this_way_id
    ,   unnest((st_dumppoints(geom)).path) as this_node_index
    ,   properties
    from 
        way
    --limit 3
    )

--select * from input
--CTE 2--------------------------------------------------
/* this expression gets the streetside nodes */    
,   sides as (
    select
        output.source_node_buffer_splits
    ,   output.source_node_id
    ,   output.source_node_index
    ,   output.source_way_id
    ,   output.child_node_hull
    from 
        input input
    ,   osm.chop_lines_and_extract_nodes(
            input.this_way_id              
        ,   input.this_node_index         
        ,   input.this_node_geom
        ) output
    )
    
--CTE 3---------------------------------------------------------------------------------------------------------------    
/* this expression creates edge segments from the chopped nodes, extending it by ~10 meters in both directions */
,   way_segment_array as (
    select
        distinct on (nodes) nodes
    ,   edge_geom
    ,   from_node_buffer_splits
    ,   to_node_buffer_splits
    ,   from_node_id
    ,   to_node_id
    ,   from_node_index
    ,   to_node_index
    ,   source_way_id
    from
----------------------------------------------
/* this subselect creates the extended edge */ 
        (select
            ST_MakeLine(
                st_translate(from_node, sin(az1) * len, cos(az1) * len)
            ,   st_translate(to_node, sin(az2) * len, cos(az2) * len)
            ) as edge_geom
        ,   array[ 
                geohash_decode(st_geohash(from_node,10))
            ,   geohash_decode(st_geohash(to_node,10))
            ] as nodes
        ,   from_node
        ,   to_node
        ,   from_node.source_node_buffer_splits as from_node_buffer_splits
        ,   to_node.source_node_buffer_splits as to_node_buffer_splits
        ,   geohash_decode(st_geohash(from_node,10)) as from_node_id
        ,   geohash_decode(st_geohash(to_node,10)) as to_node_id
        ,   from_node.source_node_index as from_node_index
        ,   to_node.source_node_index as to_node_index
        ,   from_node.source_way_id

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
             ,   0.0001 + ST_Distance(lag(this_node_geom, 1, NULL) OVER (PARTITION BY this_way_id ORDER BY this_way_id, this_node_index),this_node_geom) as len
             from
                input
            ) input
        left join
            sides from_node
        on
            from_node.source_node_id = geohash_decode(st_geohash(from_node,10))
        left join
            sides to_node
        on
            to_node.source_node_id = geohash_decode(st_geohash(to_node,10))
            
        ) way_segment        
    where
        way_segment.from_node is not null
    order by 
        nodes
    )
    
--CTE 4--------------------------------------------------------------------------------------------------------------------
/* this expression calculates the street-side index from the azimuth between the streetside nodes and the edge its source source edge segments */
,   azimuth as (
    select
        child_node as child_node_geom
    ,   geohash_decode(st_geohash(child_node,10)) as child_node_id
    ,   round(st_azimuth(child_node,st_closestpoint(edge_geom,sides.child_node))::numeric(10,2),2) as azimuth
    ,   source_node_index
    ,   type
    ,   nodes
    ,   source_way_id
--    ,   rank() over (partition by edge_geom, source_node_id order by round(st_azimuth(child_node,st_closestpoint(edge_geom,child_node))::numeric(10,2),2)) as street_side_index
    from
        (select
            from_node_id as source_node_id
        ,   (st_dump(from_node_buffer_splits)).geom as child_node
        ,   from_node_index as source_node_index
        ,   edge_geom
        ,   source_way_id
        ,   nodes
        ,   1 as type
        from
            way_segment_array
        union all select
            to_node_id as source_node_id
        ,   (st_dump(to_node_buffer_splits)).geom as child_node
        ,   from_node_index as source_node_index
        ,   edge_geom
        ,   source_way_id
        ,   nodes
        ,   2 as type
        from
            way_segment_array
        ) sides
    order by
        edge_geom
    ,   type
    ,   azimuth
--    ,   azimuth
    )
--    
-- CTE 5--------------------------------------------------------------------------------------
/* this expression creates the street sides from grouping by azimuth and limiting pairing to closest distance between points */
,   virtual_curb as (
    select
        geom
    ,   geohash_decode(st_geohash(st_lineinterpolatepoint(geom,0.5),10)) as edge_id
    ,   from_node
    ,   to_node
    ,   type
    ,   properties
    ,   round(st_length(geom::geography)::numeric(10,2),2) as length
    from
        (select
            st_makeline(a.child_node_geom,b.child_node_geom) as geom
        ,   rank() over (partition by a.nodes, a.azimuth order by st_length(st_makeline(a.child_node_geom,b.child_node_geom)::geography) asc) as index
        ,   a.child_node_id as from_node
        ,   b.child_node_id as to_node
        ,   'double' as type
        ,   i.properties
        from 
            (select * from azimuth where type = 1) a
        left join
            (select * from azimuth where type = 2) b 
        on
            a.nodes = b.nodes
        and
            a.azimuth = b.azimuth
        left join
            (select
                distinct on (this_way_id) this_way_id
            ,   properties
            from
                input
            ) i
        on 
            a.source_way_id = i.this_way_id
        ) virtual_curb
    where
        index = 1
    and 
        geom is not NULL
    
    union all select
        distinct on (geom) geom
    ,   geohash_decode(st_geohash(st_lineinterpolatepoint(geom,0.5),10)) as edge_id
    ,   geohash_decode(st_geohash(st_pointn(geom,1),10)) as from_node
    ,   geohash_decode(st_geohash(st_pointn(geom,2),10)) as to_node
    ,   'bridge' as type
    ,   '{"no":"properties"}'::jsonb as properties
    ,   round(st_length(geom::geography)::numeric(10,2),2) as length
    FROM 
        (select
            ST_AsText(st_setsrid(ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY source_node_id ORDER BY source_node_id, (pt).path), (pt).geom),4326))::geometry AS geom
        from
            (select 
                ST_DumpPoints((st_dump(child_node_hull)).geom) AS pt
            ,   source_node_id
            from
                sides
            ) as pt
        ) bridge
    where 
        geom is not null
    and
        st_length(geom::geography) > 0
    )

/* the select inserts the edges into the edges table */
select
    virtual_curb.*
from
    virtual_curb
    
/*
 * durch ein union-all-subselect werden to- und from-node per distinct on (node) node als vertices
 * ohne weitere Eigenschaften aus der edges-Tabelle erzeugt.
 * Die Adresspunkte werden als vertices mit der Eigenschaft "address" ebenfalls in die vertices-Ta-
 * belle kopiert.
 * Die Adress-Verbindungen werden per st_closestpoint aus der vertices-Tabelle erzeugt, mit from-node
 * = address-Vertex, to-node = straßen-vertex, type = 'junction' und properties = 'no:properties'
 */ 
