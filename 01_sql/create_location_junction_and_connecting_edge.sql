/*

This script creates a function to construct connecting lines
between a location and its closest topology edge.

The function returns the connector geometry, the junction point geometry,
geohash based ids of the points and the respective way_id (edge_id).

*/

DROP FUNCTION osm.create_location_junction(bigint, geometry);

CREATE OR REPLACE FUNCTION osm.create_location_junction(
    this_addr_id bigint	
,   this_addr_geom geometry
-- ,   OUT addr_id bigint
-- ,   OUT addr_location_id bigint
-- ,   OUT way_id bigint
-- ,   OUT junction_location_id bigint
-- ,   OUT junction_edge geometry
-- ,   OUT junction_node geometry
)

RETURNS TABLE (
	addr_id bigint
,   addr_location_id bigint
,   way_id bigint
,   junction_location_id bigint
,   junction_edge geometry
,   junction_node geometry
)

LANGUAGE plpgsql as $$

BEGIN
    return query
    
	with address as (
        select 
		    this_addr_id as t_addr_id
		,   this_addr_geom as t_addr_geom
	)
    select
        t_addr_id as addr_id
    ,   geohash_decode(st_geohash(t_addr_geom,10)) as addr_location_id
    ,   geohash_decode(st_geohash(st_closestpoint(way.geom, t_addr_geom::geometry),10)) as junction_location_id
    ,   way.way_id 
    ,   st_makeline(t_addr_geom, st_closestpoint(way.geom, t_addr_geom)) as junction
    ,   st_closestpoint(way.geom, t_addr_geom)::geometry as junction_node
    from
        address
    join lateral (
    select
        way.way_id
    ,   way.geom
    from
        osm.highways way
    order by
        this_addr_geom <-> way.geom 
    limit
        1
    ) as way on true
    ;
	
END;
$$
;