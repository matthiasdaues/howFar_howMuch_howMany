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
,   ghh_encode(st_x(st_lineinterpolatepoint(st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom),0.5))::numeric(10,7), st_y(st_lineinterpolatepoint(st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom),0.5))::numeric(10,7)) as point_2_road_id
,   st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom) as point_2_road_geom
,   'address_road' as point_2_road_type
,   st_length(st_makeline(ST_ClosestPoint(b.geom, a.geom), a.geom)::geography)::numeric(10,2) as point_2_road_cost
from
    vertices a
join lateral (
    select
        id as road_id
    ,   geom as road_geom
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
