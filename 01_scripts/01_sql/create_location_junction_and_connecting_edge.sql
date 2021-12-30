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
)

RETURNS TABLE (
	addr_id bigint
,   way_id bigint
,   addr_location_id bigint
,   addr_node geometry
,   junction_location_id bigint
,   junction_edge geometry
,   junction_node geometry

-- Test block ---------------------------------

-- ,   addr_distance numeric(10,2)
-- ,   addr_location geometry
-- ,   addr_location_reverse       geometry
-- ,   junction_distance numeric(10,2)
-- ,   junction_location geometry
-- ,   junction_location_reverse   geometry

-----------------------------------------------
)

LANGUAGE plpgsql as $$

DECLARE
    
	addr_geohash           text;     
    addr_location_id       bigint;   
    addr_location_reverse  geometry;
	way_geom_id            text[];
    way_geom               geometry;
	way_id                 bigint;
	junction_location      geometry; 
    junction_location_hash text;
    junction_location_id   bigint;
	junction_edge          geometry;
	junction_location_hash_reverse text;
    junction_location_reverse      geometry;

 -- test block

--     addr_geohash_reverse   text;
--     addr_location_reverse  geometry;

-----------------------------------------------------

BEGIN

--    addr_geohash               := st_geohash(this_addr_geom,10);
    addr_location_id          := geohash_decode(st_geohash(this_addr_geom,10));
    addr_location_reverse     := st_setsrid(st_centroid(st_geomfromgeohash(geohash_encode(addr_location_id))),4326)::geometry; -- will be addr_node in the result
    select into way_geom_id 
        array[st_astext(way.geom),way.way_id::text]
        from osm.highways way
        order by this_addr_geom <-> way.geom 
        limit 1;
	way_geom                  := st_setsrid(way_geom_id[1]::geometry,4326);
	way_id                    := way_geom_id[2]::bigint;
--     junction_location         := st_closestpoint(way_geom, this_addr_geom);
--     junction_location_hash    := st_geohash(junction_location::geometry,10);
    junction_location_id      := geohash_decode(st_geohash(st_closestpoint(way_geom, this_addr_geom)::geometry,10));
-- 	junction_location_hash_reverse := geohash_encode(junction_location_id);
	junction_location_reverse := st_setsrid(st_centroid(st_geomfromgeohash(geohash_encode(junction_location_id))),4326)::geometry; -- will be junction_node in the result
    junction_edge             := st_setsrid(st_makeline(addr_location_reverse, junction_location_reverse),4326);

-- test block for plausibility of hashing operation

--  addr_geohash_reverse           := geohash_encode(addr_location_id);
-- 	addr_location_reverse          := st_setsrid(st_centroid(st_geomfromgeohash(addr_geohash_reverse)),4326)::geometry;
	
----------------------------------------------------

    return query
    
    select
        this_addr_id as addr_id 
	,   way_id
    ,   addr_location_id
    ,   addr_location_reverse AS addr_node
    ,   junction_location_id 
    ,   junction_edge 
    ,   junction_location_reverse as junction_node 

-- Test block 

--     ,   st_distance(this_addr_geom::geography, addr_location_reverse::geography)::numeric(10,2) as addr_distance
--     ,   this_addr_geom as addr_location
--     ,   addr_location_reverse
--     ,   st_distance(junction_location::geography, junction_location_reverse::geography)::numeric(10,2) as junction_distance
--     ,   junction_location
--     ,   junction_location_reverse
	
---------------------------------------------

    ;
	
END;
$$
;