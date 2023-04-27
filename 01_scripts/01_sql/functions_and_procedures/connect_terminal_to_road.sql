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
--drop  procedure connect_terminal_to_road;

CREATE OR REPLACE FUNCTION _02_kubus.connect_terminal_to_road(ags5 text)

returns table (
    point_id            bigint
,   road_id             bigint
,   closest_point_geom  geometry(point, 4326)  
,   closest_point_id    bigint
,   closest_point_type  text
,   point_2_road_id     bigint
,   point_2_road_geom   geometry(linestring,4326)
,   point_2_road_type   text
,   point_2_road_cost   numeric(10,2)
)

LANGUAGE plpgsql

AS $$

declare

    point_id            bigint;
    road_id             bigint;
    closest_point_geom  geometry(point, 4326);  
    closest_point_id    bigint;
    closest_point_type  text;
    point_2_road_id     bigint;
    point_2_road_geom   geometry(linestring,4326);
    point_2_road_type   text;
    point_2_road_cost   numeric(10,2);

    rec_ags5    record;

    cur_ags5    cursor(ags5 text) 
                with vertices as (
                    select 
                        id as point_id
                    ,   geom as point_geom
                    from
                        _02_kubus.vertices_addresses
                    where
                        properties @> '[{"ags":{"ags11":"'||ags5::text||'"}}]'
                    --limit 1
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
                        a.geom <-> b.geom 
                    limit
                        1
                    ) as b on true
                ;

begin

    -- open the cursor
    open cur_ags5(ags5);

    loop
    -- fetch row into the film
        fetch cur_ags5 into rec_ags5;
    -- exit when no more row to fetch
        exit when not found;

    -- build the output

        point_id            := rec_ags5.point_id;
        road_id             := rec_ags5.road_id;
        closest_point_geom  := 
        closest_point_id    :=
        closest_point_type  :=
        point_2_road_id     :=
        point_2_road_geom   :=
        point_2_road_type   :=
        point_2_road_cost   :=

        return next;
    
    end loop;

    -- close the cursor
    close cur_ags5;

    return    
    ;
end;
$$
;