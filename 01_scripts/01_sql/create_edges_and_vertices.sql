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
	,   from_node_id bigint
    ,   from_node_geom geometry
	,   to_node_id bigint
	,   to_node_geom geometry
	,   edge_geom geometry
	,   edge_properties jsonb		
	,   edge_id bigint
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
				  'osm_highway'
				  ,   json_build_object(
				 	      'way_id'
				      ,   way.way_id
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
		
--    way_geom_enhanced := st_snap(way_geom, junction_points, 0.00001)::geometry;
	way_geom_enhanced_dump := st_dump(st_snap(way_geom, junction_points, 0.00001)::geometry);

    return query

    WITH segments AS (
 		SELECT 
 			ST_AsText(st_setsrid(ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY way_id ORDER BY way_id, (pt).path), (pt).geom),4326))::geometry AS edge
 		,   round(st_length(st_setsrid(ST_MakeLine(lag((pt).geom, 1, NULL) OVER (PARTITION BY way_id ORDER BY way_id, (pt).path), (pt).geom),4326)::geography)::numeric(10,2),2)::text as length
		FROM 
            ST_DumpPoints((way_geom_enhanced_dump).geom) AS pt 
		)
 	SELECT
		        this_way_id::bigint as way_id
		  ,     geohash_decode(
				    st_geohash(
						st_pointn(a.edge,1),10
					)
			    )::bigint as from_node_id                          -- from_node_id
		    ,	st_setsrid(
				    st_centroid(
						st_geomfromgeohash(
							st_geohash(st_pointn(a.edge,1),10
						    )
						)
					),4326
			    )::geometry as from_node_geom                      -- from_node_geom
		    ,   geohash_decode(
				    st_geohash(
						st_pointn(a.edge,2),10
					)
			    )::bigint as to_node_id                            -- to_node_id
		    ,	st_setsrid(
				    st_centroid(
						st_geomfromgeohash(
							st_geohash(
								st_pointn(a.edge,2),10
							)
						)
					),4326
			    )::geometry                                        -- to_node_geom
		    ,	a.edge::geometry                                   -- edge_geom
		    ,   jsonb_insert(
		            properties
				,   '{osm_highway,	length}'
				,   a.length::jsonb
			    ) as edge_properties                               -- edge_properties
		    ,	geohash_decode(
				    st_geohash(
						st_lineinterpolatepoint(
							a.edge::geometry,0.5
						),10
					)
				) as edge_id                                       -- edge_id
	FROM 
		segments a
	where 
	    a.edge is not NULL
	;
	

--     return query
    
--     select
--         this_way_id as way_id                      -- way_id
-- 	,   replace((jsonb_path_query(
-- 	        edges.edges
-- 		,   '$.from_node_id'
-- 	    )::text),'"','')::bigint as from_node_id   -- from_node_id
-- 	,   st_geomfromgeojson(jsonb_path_query(
-- 	        edges.edges
-- 		,   '$.from_node_geom'
-- 	    )::jsonb)::geometry as from_node_geom      -- from_node_geom
-- 	,   replace((jsonb_path_query(
-- 	        edges.edges
-- 		,   '$.to_node_id'
-- 	    )::text),'"','')::bigint as to_node_id     -- to_node_id
-- 	,   st_geomfromgeojson(jsonb_path_query(
-- 	        edges.edges
-- 		,   '$.to_node_geom'
-- 	    )::jsonb)::geometry as to_node_geom        -- to_node_geom
--     ,   st_geomfromgeojson(jsonb_path_query(
--             edges.edges 
--         ,   '$.edge_geom'
--         )::jsonb)::geometry as edge_geom           -- edge_geom
--     ,   geohash_decode(st_geohash(st_lineinterpolatepoint(st_geomfromgeojson(jsonb_path_query(
--             edges.edges 
--         ,   '$.edge_geom'
--         )::jsonb)::geometry,0.50),10)) as edge_id  -- edge_id
-- 	,   jsonb_path_query(
-- 	        edges.edges
-- 		,   '$.properties'
-- 	    )::jsonb as edge_properties                -- edge_properties
-- 	from
-- 	    (select edges) edges
-- 	;


END;
$BODY$;

ALTER FUNCTION osm.create_edges_and_vertices(bigint)
    OWNER TO gis;
