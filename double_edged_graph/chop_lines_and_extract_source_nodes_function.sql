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

DROP FUNCTION osm.chop_lines_and_extract_nodes(bigint,integer,geometry);

-- FUNCTION: osm.create_edges_and_vertices(bigint)

-- DROP FUNCTION IF EXISTS osm.create_edges_and_vertices(bigint);

CREATE OR REPLACE FUNCTION osm.chop_lines_and_extract_nodes(
    this_way_id              bigint
,   this_node_index          integer
,   this_node_geom           geometry
)

RETURNS TABLE(
    source_node_id                 bigint
,   source_node_geom               geometry
,   source_node_index              integer
--,   source_node_buffer             geometry
--,   source_node_ways               geometry
--,   source_node_intersections      geometry
--,   source_node_intersections_hash text[]
--,   source_node_degree             integer
,   source_node_buffer_splits      geometry[]
) 


LANGUAGE plpgsql as $$

declare

-- environment and source tables 
   
    ways_source                          text;

    
    source_node_id                       bigint;
    source_node_geom                     geometry;
    source_node_geom_from_hash           geometry;
    source_node_buffer                   geometry;
    source_node_index                    integer;
    source_node_ways                     geometry;
    source_node_intersections            geometry;
    source_node_intersections_hash       text[];
    source_node_degree                   integer;
    source_node_buffer_splits            geometry[];
    source_node_buffer_splits_union      geometry;
    source_node_children                 geometry;
    
    


-----------------------------------------------------

begin
    
    ways_source                          := 'osm.highways';
    
    source_node_id                       := geohash_decode(st_geohash(this_node_geom,10)); 
    source_node_geom                     := st_setsrid(st_centroid(st_geomfromgeohash(st_geohash(this_node_geom,10))),4326)::geometry;
    source_node_buffer                   := st_buffer(this_node_geom::geography,1)::geometry;
    
    /* Alternativer Ansatz oder Ergänzung: where st_touches(way.geom, source_node_geom) */

    select into source_node_ways 
        st_collect(way.geom)
        from osm.highways way
        where st_intersects(st_buffer(this_node_geom::geography,0.05)::geometry,way.geom)
    ;
   
    select into source_node_intersections            
        st_collect(sec.geom)    
        from lateral 
        (select (st_dump(st_intersection(st_exteriorring(source_node_buffer),source_node_ways))).geom) sec
    ;
    
    select into source_node_intersections_hash
        array_agg(sec.sec)
        from lateral
        (select st_geohash((st_dump(source_node_intersections)).geom,10) as sec) sec
    ;
    
    source_node_degree                   := st_numgeometries(source_node_intersections);

    select into source_node_buffer_splits
        array_agg(split.split)
        from lateral
           (select
                (st_dump((st_split(st_snap(st_exteriorring(source_node_buffer),source_node_intersections,0.0001),source_node_intersections)))).geom as split             
            )           
           split
    ;
    
--    select into source_node_buffer_splits_union
--        split_union
--        from lateral
--            (select
--                case
--                 when st_geohash(st_pointn)
--           
--    source_node
--    
-- TODO: union der splits, die  
--    select into source_node_children
--        st_collect(split.child)
--        from
--        lateral (select 
--            case 
--             when st_overlaps((st_dump((st_split(st_snap(st_exteriorring(source_node_buffer),source_node_intersections,0.0001),source_node_intersections)))).geom
--                  ,           (st_dump((st_split(st_snap(st_exteriorring(source_node_buffer),source_node_intersections,0.0001),source_node_intersections)))).geom)
--              then st_union((st_dump((st_split(st_snap(st_exteriorring(source_node_buffer),source_node_intersections,0.0001),source_node_intersections)))).geom)
--             else (st_dump((st_split(st_snap(st_exteriorring(source_node_buffer),source_node_intersections,0.0001),source_node_intersections)))).geom
--            end as child
--        ) split
--    ;
    
    return query
    
    select  
        source_node_id          
    ,   source_node_geom                     
    ,   this_node_index as source_node_index
--    ,   source_node_buffer
--    ,   source_node_ways
--    ,   source_node_intersections
--    ,   source_node_intersections_hash
--    ,   source_node_degree
    ,   source_node_buffer_splits
--    ,   this_way_id        
--    ,   source_node_geom_from_hash 
--    ,   source_node_buffer         
    ;
    
END;
$$
;
