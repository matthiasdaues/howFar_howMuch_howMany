/*

This script creates a function to get all junction points connecting 
all adjacent addresses to their nearest neighbour edge.

The function returns a linestring with the interpolated and snapped
junction points grafted into the original linestring geometry.

*/

DROP FUNCTION osm.get_location_connectors(bigint, geometry);

CREATE OR REPLACE FUNCTION osm.get_location_connectors(
    this_way_id bigint	
,   this_way_geom geometry
,   OUT location_snaps geometry
)

RETURNS geometry as $$

DECLARE
    way_buffer geometry;
  
BEGIN
    way_buffer := st_buffer(this_way_geom::geography, 50)::geometry;
	
    select into location_snaps
        st_snap(this_way_geom, st_union(st_closestpoint(this_way_geom, addr.geom)),0.1)::geometry
    from
        (select 
            point.geom
        from 
            osm.addr_combined point
        where 
            point.geom && way_buffer) addr
        join lateral (
            select
                way.way_id
            from
                osm.highways way
            order by
                addr.geom <-> way.geom 
            limit
                1
            ) as res on true
         where
             res.way_id = this_way_id
        group by
            res.way_id
    ;
	
END;
$$ LANGUAGE plpgsql;