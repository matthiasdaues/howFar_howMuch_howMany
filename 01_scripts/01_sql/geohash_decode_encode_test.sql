/*

This script tests the geometry conversion to geohash and the reverse decoding to a point geometry, 
measures the displacement of the recoded points from the original as well as 
testing the geohash conversion to big integer and back again to geohash and geometry.

*/

with hash as (
    select
	    geom
	,   st_geohash(geom,10) as hash
	from 
	    osm.addr_combined
--	limit
--	    1
    )
select
    hash
,   st_astext(geom) as wkt
--,   st_astext(st_centroid(st_geomfromgeohash(hash))) as hash_geom
--,   st_distance(geom::geography,st_centroid(st_geomfromgeohash(hash))::geography) as distance
,   geohash_decode(hash) as int
,   geohash_encode(geohash_decode(hash)) as test
--,   st_astext(st_centroid(st_geomfromgeohash(geohash_encode(geohash_decode(hash))))) as rev_hash_geom
,   st_distance(geom::geography,st_centroid(st_geomfromgeohash(geohash_encode(geohash_decode(hash))))::geography) as rev_distance 
from
    hash
order by
    rev_distance
;