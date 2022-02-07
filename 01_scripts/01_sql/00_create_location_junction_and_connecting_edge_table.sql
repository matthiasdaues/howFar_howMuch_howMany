--drop table osm.junctions cascade;
create table osm.junctions_dev (
  	addr_id bigint
,   way_id bigint
,   addr_location_id bigint
,   addr_node geometry
,   junction_location_id bigint
,   junction_edge geometry
,   junction_node geometry
    );


create index junction_addr_id_idx on osm.junctions using btree (addr_id);
create index junction_way_id_idx on osm.junctions using btree (way_id);

--truncate table osm.junctions;

with input as (
    select
	    addr_id as ad
    ,   geom as ge
	from
	    osm.addr_combined ac
	where
	    ac.geom && (select geom from osm.boundaries where tags ->> 'admin_level' = '4' and tags ->> 'name' like '%ürzbur%')
	    
--	order by
--	   random()
-- 	limit
-- 	    1
    )
insert into osm.junctions_dev
select
    test.addr_id
,   test.way_id
,   test.addr_location_id
,   test.addr_node
,   test.junction_location_id
,   test.junction_edge
,   test.junction_node
from
    input input
,   osm.create_location_junction(input.ad, input.ge) test
-- group by
--     st_geomfromgeohash(geohash_encode(junction_location_id))
