/*

This script creates a function to graft junction points created by the function 
'create_location_junction_connecting_edge()' into a given topology linestring and cutting
this linestring into true two-vertex edges.

The function returns the
- from_node ID             (bigint)
- from_node geometry       (geometry)
- to_node ID               (geometry)
- to_node geometry         (geometry)
- edge geometry            (geometry)
- edge properties          (jsonb)
- edge ID                  (bigint)

*/

DROP FUNCTION osm.create_edges_and_vertices(bigint);

CREATE OR REPLACE FUNCTION osm.create_location_junction(
    this_way_id bigint
)

RETURNS TABLE (
    from_node ID             bigint
,   from_node geometry       geometry
,   to_node ID               geometry
,   to_node geometry         geometry
,   edge geometry            geometry
,   edge properties          jsonb
,   edge ID                  bigint
)

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
    
    way_geom                 geometry;
    junction_points          geometry;
    way_geom_enhanced        geometry;



 -- test block

--     addr_geohash_reverse   text;
--     addr_location_reverse  geometry;

-----------------------------------------------------

BEGIN
    
    select into way_geom
        way.geom::geometry
        from osm.highways way
        where way_id = this_way_id
        ;
    select into junction_points
        st_union(
            junction_node::geometry
        )
        where way_id = this_way_id
        ;
    way_geom_enhanced := st_snap(way_geom, junction_points, 0.5)::geometry;
    way_geom_dump     := 

--     junction_location         := st_closestpoint(way_geom, this_addr_geom);
--     junction_location_hash    := st_geohash(junction_location::geometry,10);
    junction_location_id      := geohash_decode(st_geohash(st_closestpoint(way_geom, this_addr_geom)::geometry,10));
-- 	junction_location_hash_reverse := geohash_encode(junction_location_id);
	junction_location_reverse := st_setsrid(st_centroid(st_geomfromgeohash(geohash_encode(junction_location_id))),4326)::geometry; -- will be junction_node in the result
    junction_edge             := st_setsrid(st_makeline(this_addr_geom, junction_location_reverse),4326);

-- test block for plausibility of hashing operation

--  addr_geohash_reverse           := geohash_encode(addr_location_id);
-- 	addr_location_reverse          := st_setsrid(st_centroid(st_geomfromgeohash(addr_geohash_reverse)),4326)::geometry;
	
----------------------------------------------------

    return query
    
    select
        this_addr_id as addr_id 
	,   way_id
    ,   addr_location_id
	,   addr_location
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