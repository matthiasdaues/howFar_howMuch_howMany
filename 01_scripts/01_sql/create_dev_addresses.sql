create table osm.addr_dev as 
select
    addr_id
,   geom
from 
    osm.addr_combined ac 
,   (
    select 
        st_convexhull(st_collect(geom)) as cutter
    from
        osm.highways_dev
    ) cutter
where 
    st_intersects(geom,cutter.cutter) 