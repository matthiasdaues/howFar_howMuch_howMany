drop table osm.junctions cascade;
create table osm.junctions (
  	addr_id bigint
,   way_id bigint
,   addr_location_id bigint
,   junction_location_id bigint
,   junction_edge geometry
,   junction_node geometry
    );


create index junction_addr_id_idx on osm.junctions using btree (addr_id);
create index junction_way_id_idx on osm.junctions using btree (way_id);

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
