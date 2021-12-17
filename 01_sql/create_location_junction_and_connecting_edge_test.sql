/*

This script executes the function create_location_junction.

*/

with input as (
    select
	    addr_id
    ,   geom
	from
	    osm.addr_combined
	limit
	    100000
    )
select
    *
from
    input input
,   osm.create_location_junction(input.addr_id, input.geom)


------------------------------------------

with address as (
	select 
		addr_id as t_addr_id
	,   geom as t_addr_geom
	from 
	    osm.addr_combined
	limit
	    10
)
select
	t_addr_id as addr_id
,   geohash_decode(st_geohash(t_addr_geom,10)) as addr_location_id
,   geohash_decode(st_geohash(st_closestpoint(way.geom, t_addr_geom::geometry),10)) as junction_location_id
,   way.way_id 
,   st_makeline(t_addr_geom, st_closestpoint(way.geom, t_addr_geom)) as junction
,   st_closestpoint(way.geom, t_addr_geom)::geometry as junction_node
,   st_makeline(st_closestpoint(way.geom, t_addr_geom)::geometry, st_setsrid(st_centroid(st_geomfromgeohash(st_geohash(st_closestpoint(way.geom, t_addr_geom::geometry),10))),4326)) as geom
from
	address
join lateral (
select
	way.way_id
,   way.geom
from
	osm.highways way
order by
	t_addr_geom <-> way.geom 
limit
	1
) as way on true