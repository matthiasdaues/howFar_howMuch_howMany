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

DROP FUNCTION osm.  (bigint);

-- FUNCTION: osm.create_edges_and_vertices(bigint)

-- DROP FUNCTION IF EXISTS osm.create_edges_and_vertices(bigint);

CREATE OR REPLACE FUNCTION osm.create_edges_and_vertices(
	this_way_id bigint)
    RETURNS TABLE(way_id bigint, way_geom geometry, junction_points geometry, way_geom_enhanced geometry) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
    
    way_geom                      geometry;
    junction_points               geometry;
	way_geom_enhanced             geometry;
	way_geom_enhanced_dump        geometry;
    way_geom_enhanced_dump_points geometry;

-- test block

--     addr_geohash_reverse   text;
--     addr_location_reverse  geometry;

-----------------------------------------------------

BEGIN
    
    select into way_geom
        way.geom::geometry
        from osm.highways way
        where way.way_id = this_way_id
        ;
    select into junction_points
        st_union(
            junction_node::geometry
        )
		from osm.junctions junctions
        where junctions.way_id = this_way_id
        ;
way_geom_enhanced := st_snap(way_geom, junction_points, 0.5)::geometry;
--	way_geom_enhanced_dump := st_dump(way_geom_enhanced);
--  way_geom_enhanced_dump_points := st_dumpPoints(way_geom_enhanced_dump)::geometry;

-- test block for plausibility of hashing operation

	
----------------------------------------------------

    return query
    
    select
        this_way_id as way_id
    ,   way_geom
    ,   junction_points
    ,   way_geom_enhanced

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
$BODY$;

ALTER FUNCTION osm.create_edges_and_vertices(bigint)
    OWNER TO gis;
