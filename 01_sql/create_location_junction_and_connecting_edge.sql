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

DECLARE
    
	addr_geohash      text     
    addr_location_id  bigint   
    way_geom          geometry
	junction_location geometry 

BEGIN



    addr_geohash          := st_geohash(this_addr_geom,10);
    addr_location_id      := geohash_decode(addr_geohash);
    select into way_geom 
        way.geom::geometry
        from osm.highways way
        order by this_addr_geom <-> way.geom 
        limit 1; 
    junction_location      := st_closestpoint(way_geom, t_addr_geom)
    junction_location_hash := st_geohash(junction_location::geometry,10)

    return query
    
	with address as (
        select 
		    this_addr_id as t_addr_id
		,   this_addr_geom as t_addr_geom
	)
    select
        t_addr_id as addr_id
    ,   addr_location_id
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