/*

This function encodes the centerpoint of a linestring of wgs84
coordinates to a bigint hilbert curve index.

*/

CREATE OR REPLACE FUNCTION public.ghh_encode_linestring(x numeric, y numeric)
 RETURNS bigint
 LANGUAGE plpython3u
AS $function$
import geohash_hilbert as ghh
from decimal import Decimal
location_id = int(ghh.encode(round(float(x),7), round(float(y),7), precision=31, bits_per_char=2),4)
return location_id
$function$
;
