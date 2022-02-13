/*

What does it do?

TODO: 
- get the azimuth of the child nodes to the respective edges
    - source for the extended linestring: https://gis.stackexchange.com/questions/104439/how-to-extend-a-straight-line-in-postgis
- construct the convex hull around the child nodes and split it into straight segments
- construct the edges from azimuth, way_id and index

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
,   source_node_degree             integer
--,   source_node_buffer             geometry
--,   source_node_buffer_ring_joint  geometry
--,   source_node_ways               geometry
--,   source_node_intersections      geometry
--,   source_node_intersections_hash text[]
--,   source_node_degree             integer
,   source_node_buffer_splits      geometry
,   child_node_hull                geometry
) 


LANGUAGE plpgsql as $$

declare

-- environment and source tables 
   
    ways_source                          text;

    
    source_node_id                       bigint;
    source_node_geom                     geometry;
    source_node_geom_from_hash           geometry;
    source_node_buffer                   geometry;
    source_node_buffer_ring_joint        geometry;
    source_node_index                    integer;
    source_node_ways                     geometry;
    source_node_intersections            geometry;
    source_node_intersections_hash       text[];
    source_node_degree                   integer;
    source_node_buffer_splits            geometry;
    source_node_buffer_splits_union      geometry;
    source_node_children                 geometry;
    child_node_hull                      geometry;
    
    


-----------------------------------------------------

begin
    
    ways_source                          := 'osm.highways';
    
    source_node_id                       := geohash_decode(st_geohash(this_node_geom,10)); 
    source_node_geom                     := st_setsrid(st_centroid(st_geomfromgeohash(st_geohash(this_node_geom,10))),4326)::geometry;
    source_node_buffer                   := st_buffer(this_node_geom::geography,1)::geometry;
    source_node_buffer_ring_joint        := st_pointn(st_exteriorring(source_node_buffer),1); 
    
    /* select the road segments that connect to the processed vertex */
    select into source_node_ways 
        st_collect(way.geom)
        from osm.edges_dev way
        where st_intersects(st_buffer(this_node_geom::geography,0.05)::geometry,way.geom)
        /* Alternativer Ansatz oder Ergänzung: where st_touches(way.geom, source_node_geom) */
        --and   st_touches()
    ;
    
    /* construct the intersection points between the vertex' buffer ring and the road segments */
    select into source_node_intersections            
        st_collect(sec.geom)    
        from lateral 
        (select (st_dump(st_intersection(st_exteriorring(source_node_buffer),source_node_ways))).geom) sec
    ;
    
    /* calculate the geohash of the intersection point */
    select into source_node_intersections_hash
        array_agg(sec.sec)
        from lateral
        (select st_geohash((st_dump(source_node_intersections)).geom,10) as sec) sec
    ;
    
    /* calculate the vertex' degree by counting the intersections of the buffer with connecting road segments */
    source_node_degree                   := st_numgeometries(source_node_intersections);

    /* construct the buffer segments between the intersection points. Note the st_union needed to dissolve the remaining ring-line segments */
    with split as (
        select
            (st_dump((st_split(st_snap(st_exteriorring(source_node_buffer),source_node_intersections,0.0001),source_node_intersections)))).geom as split
        )
    select into source_node_buffer_splits
        case 
         when source_node_degree = 1 
          then st_collect(st_lineinterpolatepoints(split.split,0.5))
         else st_collect(st_lineinterpolatepoint(split.split,0.5))
        end
        from 
            (select
                st_linemerge(st_union(split.split)) as split
             from 
                split
             where
                st_touches(split.split,source_node_buffer_ring_joint) is true
             union all select
                split.split as split
             from
                split
             where
                st_touches(split.split,source_node_buffer_ring_joint) is false 
             ) split       
    ;

    child_node_hull                      := case 
                                             when geometrytype(st_convexhull(source_node_buffer_splits)) = 'LINESTRING' 
                                              then st_convexhull(source_node_buffer_splits) 
                                             else st_exteriorring(st_convexhull(source_node_buffer_splits)) 
                                            end
    ;

    /* extending the edge to get azimuth */
    --SELECT ST_MakeLine(ST_TRANSLATE(a, sin(az1) * len, cos(az1) * 
--len),ST_TRANSLATE(b,sin(az2) * len, cos(az2) * len))
--
--  FROM (
--    SELECT a, b, ST_Azimuth(a,b) AS az1, ST_Azimuth(b, a) AS az2, ST_Distance(a,b) + 1000 AS len
--      FROM (
--        SELECT ST_StartPoint(the_geom) AS a, ST_EndPoint(the_geom) AS b
--          FROM ST_MakeLine(ST_MakePoint(1,2), ST_MakePoint(3,4)) AS the_geom
--    ) AS sub
--) AS sub2
    
    /* return the process results */
    return query
    
    select  
        source_node_id          
    ,   source_node_geom                     
    ,   this_node_index as source_node_index
    ,   source_node_degree
--    ,   source_node_buffer
--    ,   source_node_buffer_ring_joint
--    ,   source_node_ways
--    ,   source_node_intersections
--    ,   source_node_intersections_hash
--    ,   source_node_degree
    ,   source_node_buffer_splits
    ,   child_node_hull
--    ,   this_way_id        
--    ,   source_node_geom_from_hash 
--    ,   source_node_buffer     
    
    ;
    
END;
$$
;
