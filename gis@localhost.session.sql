select 
    *
from
    osm.boundaries
where
    tags ->> 'name' like '%amburg%'
;