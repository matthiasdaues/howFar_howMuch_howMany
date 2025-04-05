CREATE OR REPLACE FUNCTION public.ghh_decode_to_wkt(id bigint)
 RETURNS geometry
 LANGUAGE plpython3u
 IMMUTABLE
AS $function$

import geohash_hilbert as ghh

hash      = str(id % 4)
remainder = id // 4

while remainder != 0:
    hash = str(str(int(remainder) % 4) + hash)
    remainder = remainder // 4

position = ghh.decode(str(hash), bits_per_char = 2)
geometry = 'POINT(' + str(round(position[0],7)) + ' ' + str(round(position[1],7)) + ')'

return geometry

$function$
;
