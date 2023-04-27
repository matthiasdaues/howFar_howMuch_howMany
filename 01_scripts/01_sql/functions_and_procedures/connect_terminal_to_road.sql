-- point_id
-- road_id
-- closest_point_geom
-- closest_point_id
-- closest_point_type
-- point_2_road_id
-- point_2_road_geom
-- point_2_road_type
-- point_2_road_cost

with vertices as (
    select 
        id 
    ,   geom
    from
        _02_kubus.vertices_addresses
    where
        properties @> '[{"ags":{"ags11":"05962024002"}}]'
    --limit 1
)
select 
	a.id as point_id
,   b.id as road_id
,   ST_ClosestPoint(b.geom, a.geom) as closest_point_geom
,   ghh_encode(st_x(ST_ClosestPoint(b.geom, a.geom))::numeric(10,7),st_y(ST_ClosestPoint(b.geom, a.geom))::numeric(10,7)) as closest_point_id
,   'address_road' as closest_point_type
--,   ghh_encode(st_x(st_lineinterpolatepoint(st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom),0.5))::numeric(10,7), st_y(st_lineinterpolatepoint(st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom),0.5))::numeric(10,7)) as point_2_road_id
,   st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom) as point_2_road_geom
,   'address_road' as point_2_road_type
,   st_length(st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom)::geography)::numeric(10,2) as point_2_road_cost
from
    vertices a
join lateral (
    select
        id
    ,   geom
    from
        osm.road_network b
    order by
        a.geom <-> b.geom 
    limit
        1
    ) as b on true
order by
    road_id, point_id;

select 
	a.id as point_id
,   b.id as road_id
,   ST_ClosestPoint(b.geom, a.geom) as closest_point_geom
,   ghh_encode(st_x(ST_ClosestPoint(b.geom, a.geom))::numeric(10,7),st_y(ST_ClosestPoint(b.geom, a.geom))::numeric(10,7)) as closest_point_id
,   'address_road' as closest_point_type
,   0 as point_2_road_id
,   st_ShortestLine(b.geom, a.geom) as point_2_road_geom
,   'address_road' as point_2_road_type
,   st_length(st_ShortestLine (b.geom, a.geom)::geography) as point_2_road_cost
from
	_02_kubus.vertices_addresses a
join lateral
	(select b.* from osm.road_network b order by a.geom <-> b.geom limit 1) b on true
limit 10
;


----------------------------------------

-- create a stored procedure that performs a 1 to many 
-- shortest path routing over all vertices
-- 
-- example: call _02_kubus.near_net_routing_over_vertices_addresses('[...]');


-- if procedure exists:
--drop  procedure near_net_routing_over_vertices_addresses;

CREATE OR REPLACE PROCEDURE _02_kubus.near_net_routing_over_vertices_addresses(input_id character varying, input_ref_date date)
 LANGUAGE plpgsql
AS $procedure$

declare

    ref_date date;

begin

    -- This is the selector grid variable

    with id as (
        select input_id::text as id
        )

    -- The first cte selects the target points for the dijkstra function
    -- as all address vertices within the selector grid

    ,   targets as ( 
        select 
            '1'
        ,   array_agg(a.id) as targets
        from
            _02_kubus.vertices_addresses a
        ,   osm4routing2.geohash b
        where
            b.geometry && a.geom
        and
            b.id = (select id from id)
        )
        
    -- In a first round the query collects the gross distance
    -- for all address vertices.
    -- The subset of the graph is selected in the dijkstra
    -- function call as all edges intersecting the selector
    -- grid buffered by 1000m plus all "zero node edges"

    ,   cost as (
        select 
            end_vid
        ,   agg_cost as cost
        FROM 
            pgr_DijkstraCost(
            'SELECT 
                id
            ,   source_vertex_id as source
            ,   target_vertex_id as target
            ,   length as cost
            FROM 
                _02_kubus.mv_edges_near_net e
            where
                (select st_buffer(geometry::geography,1000)::geometry from osm4routing2.geohash where geohash_decode(id) = '||(select geohash_decode(id) from id)||') && e.geometry 
            or
                target_vertex_id = 2305843009213693952
            '
        ,   2305843009213693952
        ,   (select targets from targets)
        ,   false
            )
        )

    -- A second round of dijkstra's algorithms collects
    -- the full path from source vertex to target vertex
    -- as well as joining the geometries of the edges in
    -- order to display the route on a map

    ,   details as (
        select 
            end_vid as id
        ,   (array_agg(d.node))[2] as access_point
        ,   (array_agg(d.edge))[2:] as path
        ,   sum(d.cost)::numeric(10,2) as distance
        ,   st_multi(st_collect(e.geometry)) as geom
        FROM 
            pgr_Dijkstra(
            'SELECT 
                id
            ,   source_vertex_id as source
            ,   target_vertex_id as target
            ,   length as cost
            FROM 
                _02_kubus.mv_edges_near_net e
            where
                (select st_buffer(geometry::geography,1000)::geometry from osm4routing2.geohash where geohash_decode(id) = '||(select geohash_decode(id) from id)||') && e.geometry 
            or
                target_vertex_id = 2305843009213693952
                '
        ,   2305843009213693952
        ,   (select array_agg(end_vid) from cost where cost <=260)
        ,   false
            ) d
        left join (
            SELECT 
                    id
                ,   geometry
                FROM 
                    _02_kubus.mv_edges_near_net e
                where
                    (select st_buffer(geometry::geography,1000)::geometry from osm4routing2.geohash where id = input_id::text) && e.geometry
                and
                    target_vertex_id != 2305843009213693952
            ) e on d.edge = e.id
        group by
            end_vid
        order by access_point
        )

    --select *, '@Value(datestamp)' as ref_date from details    

    INSERT INTO _42_products.near_net_results
    ( id, access_point, path, distance, geom, ref_date )
    ( SELECT id, access_point, path, distance, geom, input_ref_date as ref_date FROM details )
    ;    
end;
$procedure$
;
