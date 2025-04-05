CREATE OR REPLACE FUNCTION public.ghh_decode_hash(code character varying)
 RETURNS geometry
 LANGUAGE plpython3u
 IMMUTABLE
AS $function$

    import geohash_hilbert as ghh

    position = ghh.decode(str(code), bits_per_char = 2)
    geometry = 'POINT(' + str(round(position[0],7)) + ' ' + str(round(position[1],7)) + ')'

    return geometry

$function$
;
