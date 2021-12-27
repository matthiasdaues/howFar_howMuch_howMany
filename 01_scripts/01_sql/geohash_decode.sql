/*

This decodes a geohash from the postGIS function st_geohash(geom,10) to big integer.
10 is the highest precision for which this function will give a meaningful result 
that can be re-encoded to geohash and in turn be converted back to a lon/lat-bounding box
whose centroid will be at most half a metre displaced from the original point.

*/

CREATE OR REPLACE FUNCTION geohash_decode(IN base32 varchar)
  RETURNS bigint AS $$
        DECLARE
			a char[];
			ret bigint;
			i int;
			val int;
			chars varchar;
		BEGIN
		chars := '0123456789bcdefghjkmnpqrstuvwxyz';
 
		FOR i IN REVERSE char_length(base32)..1 LOOP
			a := a || substring(lower(base32) FROM i FOR 1)::char;
		END LOOP;
		i := 0;
		ret := 0;
		WHILE i < (array_length(a,1)) LOOP		
			val := position(a[i+1] IN chars)-1;
			ret := ret + (val * (32 ^ i));
			i := i + 1;
		END LOOP;
 
		RETURN ret;
 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;