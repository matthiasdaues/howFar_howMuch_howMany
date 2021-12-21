drop table if exists osm.junctions cascade;
create table osm.edges (
  	edge_id    bigint
,   to_node    bigint
,   from_node  bigint
,   geom       geometry(LineString,4326)
,   properties jsonb
,   valid_from date
,   valid_to   date
)
;


create index edge_id_idx on osm.edges using btree (edges_id);
create index edge_from_node_id_idx on osm.edges using btree (from_node);
create index edge_to_node_id_idx on osm.edges using btree (to_node);
create index edge_geom_idx on osm.edges using gist (geom);

truncate table osm.junctions;

with input as (
    select
	    addr_id as ad
    ,   geom as ge
	from
	    osm.addr_combined
--	order by
--	   random()
--	limit
--	    1
    )
insert into osm.junctions
select
    test.*
from
    input input
,   osm.create_location_junction(input.ad, input.ge) test
-- group by
--     st_geomfromgeohash(geohash_encode(junction_location_id))
