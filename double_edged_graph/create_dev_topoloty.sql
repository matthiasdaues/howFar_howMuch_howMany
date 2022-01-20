drop table osm.double_edged_graph_dev;
create table osm.double_edged_graph_dev as
select
    *
from
    osm.highways 
where 
    st_buffer(st_point(9.9392398,49.7980151)::geography,150) && geom
;

-- select st_buffer(st_point(9.9392398,49.7980151)::geography,150) as point;

select 

