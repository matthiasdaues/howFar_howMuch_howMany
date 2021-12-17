/*

This script executes the function create_location_junction.

*/

with input as (
    select
	    addr_id
    ,   geom
	from
	    osm.addr_combined
	limit
	    100000
    )
select
    *
from
    input input
,   osm.create_location_junction(input.addr_id, input.geom)