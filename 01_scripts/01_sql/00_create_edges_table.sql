--drop table if exists osm.edges cascade;
-- create table osm.edges (
--   	edge_id    bigint
-- ,   from_node    bigint
-- ,   to_node  bigint
-- ,   geom       geometry(LineString,4326)
-- ,   properties jsonb
-- ,   valid_from date
-- ,   valid_to   date
-- )
-- ;


-- create index edge_id_idx on osm.edges using btree (edge_id);
-- create index edge_from_node_id_idx on osm.edges using btree (from_node);
-- create index edge_to_node_id_idx on osm.edges using btree (to_node);
-- create index edge_geom_idx on osm.edges using gist (geom);

truncate table osm.edges;

with input as (
    select
	    way_id as way
	from
	    osm.junctions
-- 	where
-- 	    way_id = 22907279
	group by
	    way_id
	-- order by
	--    random()
    -- limit
	--     random()*10000
    )
insert into osm.edges
select
    test.edge_id
,   test.from_node_id as from_node
,   test.to_node_id as to_node
,   test.edge_geom as geom
,   test.edge_properties as properties
-- ,   0 as valid_from
-- ,   0 as valid_to

from
    input input
,   osm.create_edges_and_vertices(input.way) test

union all 

select 

    geohash_decode(
        st_geohash(
            st_lineinterpolatepoint(
                junction_edge::geometry,0.5
            ),10
        )
    ) as edge_id                                   
,   addr_location_id as from_node
,   junction_location_id as to_node
,   junction_edge as geom
,   null as properties
-- ,   0 as valid_from
-- ,   0 as valid_to

from
   osm.junctions 
-- where
--    way_id = 22907279
