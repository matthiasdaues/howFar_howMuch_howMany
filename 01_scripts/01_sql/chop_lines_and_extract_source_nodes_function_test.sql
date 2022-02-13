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
       --limit 1
        ) a
    --limit 1
    )
select
    output.*
--,   unnest(source_node_buffer_splits)
--,   sum(cardinality(output.source_node_buffer_splits))
from
    input input
,   osm.chop_lines_and_extract_nodes(
        input.this_way_id              
    ,   input.this_node_index         
    ,   input.this_node_geom
    ) output
    
