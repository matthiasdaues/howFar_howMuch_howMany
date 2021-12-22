select 
    *
from
    osm.boundaries
where (
        tags ->> 'name'  ('%amburg%', '%erlin%')
    and 
        tags ->> 'admin_level' = '4'
    )
-- or
--     tags ->> 'admin_level' = '6'
;