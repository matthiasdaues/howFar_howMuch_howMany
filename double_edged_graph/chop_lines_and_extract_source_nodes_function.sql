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

DROP FUNCTION osm.chop_lines_and_extract_source_nodes(bigint);

-- FUNCTION: osm.create_edges_and_vertices(bigint)

-- DROP FUNCTION IF EXISTS osm.create_edges_and_vertices(bigint);

CREATE OR REPLACE FUNCTION osm.chop_lines_and_extract_source_nodes(
	this_way_id bigint)
    RETURNS TABLE(
		node_id bigint
	,   geom geometry
	) 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$

DECLARE
    
    node_id                       bigint;
    node_geom_collection          geometry;


-----------------------------------------------------

BEGIN
    
	select into way_


END;
$BODY$;

ALTER FUNCTION osm.create_edges_and_vertices(bigint)
    OWNER TO gis;
