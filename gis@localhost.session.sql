select 
    *
from
    osm.boundaries
where (
        tags ->> 'name' in ('%amburg%','%erlin%')
    and 
        tags ->> 'admin_level' = '4'
    )
-- or
--     tags ->> 'admin_level' = '6'
;