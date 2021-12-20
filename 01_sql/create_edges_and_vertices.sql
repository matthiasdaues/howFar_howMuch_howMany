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

-- FUNCTION: osm.create_edges_and_vertices(bigint)

-- DROP FUNCTION IF EXISTS osm.create_edges_and_vertices(bigint);

CREATE OR REPLACE FUNCTION osm.create_edges_and_vertices(
	this_way_id bigint)
    RETURNS TABLE(
		way_id bigint
--	,   way_geom geometry
--	,   junction_points geometry
--	,   way_geom_enhanced geometry
--	,   properties jsonb
	,   edges jsonb
	) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
    
    way_geom                      geometry;
    junction_points               geometry;
	way_geom_enhanced             geometry;
	way_geom_enhanced_dump        geometry_dump;
    way_geom_enhanced_dump_points geometry_dump;
	
	edges                         jsonb;
	
	from_node_id                  bigint;
	from_node_geom                geometry;
	to_node_id                    bigint;
	to_node_geom                  geometry;
	edge_id                       bigint;
	edge_geom                     geometry;
	properties                    jsonb;


-----------------------------------------------------

BEGIN
    
	select into properties 
	    json_build_object(
				  'highways'
				  ,   json_build_object(
				 	      'way_id'
				      ,   way.way_id
				 	  ,   'length'
					  ,   round(st_length(way.geom::geography)::numeric,2)
					  ,   'type'
					  ,   way.type
					  ,   'surface'
					  ,   way.surface
					  ,   'name'
					  ,   way.name                 )
				  ) 
        from osm.highways way
        where way.way_id = this_way_id
	    ;
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
    way_geom_enhanced := st_snap(way_geom, junction_points, 0.00001)::geometry;
	way_geom_enhanced_dump := st_dump(way_geom_enhanced);

    WITH segments AS (
 		SELECT 
 			ST_AsText(ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY way_id ORDER BY way_id, (pt).path), (pt).geom)) AS edge
 		FROM 
            ST_DumpPoints((way_geom_enhanced_dump).geom) AS pt 
		)
 	SELECT into edges
	    jsonb_agg(
			jsonb_build_object(
			'from_node_id'
		,   geohash_decode(st_geohash(st_pointn(a.edge,1),10))::text  -- from_node_id
		,   'from_node_geom'
		,	st_setsrid(st_centroid(st_geomfromgeohash(st_geohash(st_pointn(a.edge,1),10))),4326)::geometry  -- from_node_geom
		,   'edge_geom'
		,	st_setsrid(a.edge,4326)     -- edge_geom
		,   'properties'
		,   properties::jsonb
			)
		)
	FROM 
		segments a
	where 
	    a.edge is not NULL
	;
	
	    
-- test block for plausibility of hashing operation

	
----------------------------------------------------

    return query
    
    select
        this_way_id as way_id
--    ,   way_geom
--    ,   junction_points
--    ,   way_geom_enhanced
--	,   properties
--	,   st_setsrid(unnest(edges[2]),4326) as edge
    ,   edges
	

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
