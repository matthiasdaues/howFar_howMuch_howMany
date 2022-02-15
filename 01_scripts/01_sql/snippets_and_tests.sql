with input_node as (
    select
        geohash_decode(st_geohash((st_dumppoints(a.geom)).geom,10)) as node_id
    ,   st_setsrid(st_centroid(st_geomfromgeohash(geohash_encode(geohash_decode(st_geohash((st_dumppoints(a.geom)).geom,10))))),4326)::geometry as hash_geom
    ,   (st_dumppoints(a.geom)).geom as geom
    ,   way_id
    ,   (st_dumppoints(a.geom)).path as index
    ,   st_buffer((st_dumppoints(a.geom)).geom::geography,1)::geometry as buffer
    from 
        (select
            way_id
        ,   geom
        from
            osm.double_edged_graph_dev 
        --limit 1
        ) a
    limit 1
    )
select
    i.node_id
,   i.buffer
,   i.geom as geom_old
,   i.hash_geom as geom
,   i.way_id
,   index[1] as index
,   jsonb_build_array(h.way_id,h."type",h."name",h.surface)
,   st_length(st_makeline(i.geom,i.hash_geom)::geography) as displacement
,   st_exteriorring(i.buffer) as test
,   (st_dump(st_intersection(st_exteriorring(i.buffer),h.geom))).geom as intersection
from 
    osm.highways h
,   input_node i
where 
    i.buffer && h.geom
group by 
    i.node_id
,   i.geom
,   i.hash_geom 
,   i.way_id
,   i.index[1]
,   h.way_id
,   h."type" 
,   h."name" 
,   h.geom
,   h.surface 
,   i.buffer
order by 
    way_id
,   index[1] 
,   node_id
;



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
    *
,   (st_dump(st_intersection(st_exteriorring(st_buffer(this_node_geom::geography,1)::geometry),way.geom))).geom
,   degrees(st_azimuth(this_node_geom,(st_dump(st_intersection(st_exteriorring(st_buffer(this_node_geom::geography,1)::geometry),way.geom))).geom))
,   st_collect(
        st_project(this_node_geom::geography , 1 , radians(degrees(st_azimuth(this_node_geom,(st_dump(st_intersection(st_exteriorring(st_buffer(this_node_geom::geography,1)::geometry),way.geom))).geom))+90))::geometry,
    ,   st_project(this_node_geom::geography , 1 , radians(degrees(st_azimuth(this_node_geom,(st_dump(st_intersection(st_exteriorring(st_buffer(this_node_geom::geography,1)::geometry),way.geom))).geom))-90))::geometry           
    )
from 
    input i
,   osm.highways_dev way
where 
    i.this_way_id = way.way_id
