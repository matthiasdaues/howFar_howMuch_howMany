with area as (
    select 
        st_transform(b.geom,4326) as geom
    FROM
        base.l_06_mu_de_25832_po_250 b
    where 
        gen = 'Hannover'
    ),
rough_selection as (
    SELECT
        r.*
    FROM
        osm.highways r
    ,   area a
    where
        a.geom && r.geom
    )
-- create table base.road_network_subset as
SELECT
    r.*
FROM
    rough_selection r 
,   area a 
where
    st_within(r.geom, a.geom)
;

