-- point_id
-- road_id
-- closest_point_geom
-- closest_point_id
-- closest_point_type
-- point_2_road_id
-- point_2_road_geom
-- point_2_road_type
-- point_2_road_cost

----------------------------------------

-- create a stored procedure that connects addresses and other points
-- of interest to a road network via st_closestpoint().
-- example: call _02_kubus.connect_terminal_to_road('[...]');


-- if procedure exists:
drop  function _02_kubus.connect_terminal_to_road;

CREATE OR REPLACE FUNCTION _02_kubus.connect_terminal_to_road(ags5 text)

returns table (
    point_id            bigint
,   road_id             bigint
,   closest_point_geom  geometry(point, 4326)  
,   closest_point_id    bigint
,   closest_point_type  text
,   point_2_road_geom   geometry(linestring,4326)
,   point_2_road_id     bigint
,   point_2_road_type   text
,   point_2_road_cost   numeric(10,2)
)

LANGUAGE plpgsql

AS $$

declare

	-- declare a variable for the center of the connecting edge
	-- which is not part of the result set
    point_2_road_geom_center    geometry(point,4326);

   	-- declare the variable holding the row from
    -- the result set of the cursor query
    rec_ags5  		 			record;

begin
 
	for rec_ags5 in (
                with vertices as (
                    select 
                        id as point_id
                    ,   geom as point_geom
                    from
                        _02_kubus.vertices_addresses
                    where
                        properties @> jsonb_build_array(jsonb_build_object('ags', jsonb_build_object('ags5',ags5::text)))
                    )
                select 
                    a.point_id
                ,   a.point_geom
                ,   b.road_id
                ,   b.road_geom
                from
                    vertices a
                join lateral (
                    select
                        id as road_id
                    ,   geom as road_geom
                    from
                        osm.road_network b
                    order by
                        a.point_geom <-> b.geom 
                    limit
                        1
                    ) as b on true
        ) loop  

	        -- build the output

        point_id                    := rec_ags5.point_id;
        road_id                     := rec_ags5.road_id;
        closest_point_geom          := ST_ClosestPoint(rec_ags5.road_geom, rec_ags5.point_geom);
        closest_point_id            := ghh_encode(st_x(closest_point_geom)::numeric(10,7),st_y(closest_point_geom)::numeric(10,7));
        closest_point_type          := 'address_road';
        point_2_road_geom           := st_makeline(closest_point_geom, rec_ags5.point_geom);
        point_2_road_geom_center    := st_lineinterpolatepoint(point_2_road_geom,0.5);
        point_2_road_id             := ghh_encode(st_x(point_2_road_geom_center)::numeric(10,7), st_y(point_2_road_geom_center)::numeric(10,7));
        point_2_road_type           := 'address_2_road';
        point_2_road_cost           := st_length(point_2_road_geom::geography)::numeric(10,2);

        return next;
    
    end loop;
   
end;
$$
;