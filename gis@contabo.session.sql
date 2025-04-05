with vertex as (
    select 
        *
    from
        _02_kubus.vertices_addresses
    limit
        1
    )
,   edge as (
    select 
        *
    from
        osm.road_network
    order by
        geom <-> (select geom from vertex)
    limit 1
    )
select 
    edge.id as edge_id
,   vertex.id as vertex_id
,   st_closestpoint(edge.geom, vertex.geom) as geom
from
    edge
,   vertex
;
