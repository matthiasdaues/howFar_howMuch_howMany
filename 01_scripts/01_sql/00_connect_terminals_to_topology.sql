select 
    st_makeline(addr.geom, st_closestpoint(res.geom, addr.geom))::geometry as geom
,   st_astext(st_makeline(addr.geom, st_closestpoint(addr.geom, res.geom ))::geometry) as geom_text
,   addr.addr_id
,   res.way_id
from
--   (select node_id, geom from osm.addr_points where node_id = 2435899881) addr
    osm.addr_combined addr
join lateral (
select
    way_id
,   geom
from
    osm.highways way
order by
    addr.geom <-> way.geom 
limit
    1
) as res on true;

/*
select 
    st_makeline(addr.geom, st_closestpoint(res.geom, addr.geom))::geometry as geom
,   st_astext(st_makeline(addr.geom, st_closestpoint(addr.geom, res.geom ))::geometry) as geom_text
,   addr.addr_id
,   res.way_id
from
--   (select node_id, geom from osm.addr_points where node_id = 2435899881) addr
    (select 
	     *
	 from
	     osm.addr_combined addr
	 inner join  
	     osm.boundaries selector
	 on 
	     addr.geom && selector.geom and selector.area_id = -180627
	 ) as addr
	     
join lateral (
select
    way_id
,   geom
from
    osm.highways way
order by
    addr.geom <-> way.geom 
limit
    1
) as res on true;



*/

/*

select
 (st_dump(st_collect(
		st_makeline(addr.geom, st_closestpoint(res.geom, addr.geom))
		,   st_split(
				st_snap(res.geom
			,   st_closestpoint(res.geom, addr.geom)
			,   0.01
			)
			,   st_closestpoint(res.geom, addr.geom)
	    )))).geom as geom
from
   (select 
	    point.addr_id
	,   point.geom 
	from 
	    osm.addr_combined point
    ,   (select geom from osm.highways where way_id = 10075347) line
	where 
	    point.geom::geography <-> line.geom::geography <= 100) addr
join lateral (
select
    way.way_id
,   way.geom
from
    osm.highways way
order by
    addr.geom <-> way.geom 
limit
    1
) as res on true;



*/




