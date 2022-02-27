with grafts as (
    select
	    way_id
--	,   array_agg(junction_location_id) as junction_location_id
	,   st_union(junction_node) as nodes
	,   st_union(junction_edge)
	from
	    osm.junctions
	group by
	    way_id
	--limit
	--    1
    )
select
    st_snap(
        res.geom
	,   grafts.nodes
	,   0.5
	)::geometry as new_road
from
    grafts grafts
join lateral
    (select
	    h.way_id
	,   h.geom
	from
	    osm.highways h
	where
	    grafts.way_id = h.way_id
	) res on true
;