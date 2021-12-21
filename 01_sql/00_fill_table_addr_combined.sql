truncate table osm.addr_combined;

insert into osm.addr_combined
    select
        node_id as addr_id
	,   geom
    from
	    osm.addr_points
union all
    select
	    area_id as addr_id
	,   st_pointonsurface(geom) as geom
    from
	    osm.addr_polys

	    