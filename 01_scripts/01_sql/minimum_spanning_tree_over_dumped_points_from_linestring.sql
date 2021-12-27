with tree_points as(
	with input as (
		select
			way_id as way
		,	count(way_id) as count
		,   array_agg(junction_location_id) as junction_location_id
		from
			osm.junctions
		where
			way_id = 22907279
		group by
			way_id
		--	order by
		--	   random()
		--	limit
		--	    1000
    	)
	select
	    (st_dumppoints((st_dump(st_snap(test.way_geom, test.junction_points, 0.1))).geom)).path[1] as id
    ,   (st_dumppoints((st_dump(st_snap(test.way_geom, test.junction_points, 0.1))).geom)).geom as geom
	from
		input input
	,   osm.create_edges_and_vertices(input.way) test
)
SELECT (minimum_spanning_tree_calc( minimum_spanning_tree(geom ,  id::text ORDER BY id ASC) )).* 
FROM tree_points 