/*

This function encodes a big integer into a geohash that can be converted into a bounding box
using the the postGIS function st_geomfromgeohash(hash).

*/

CREATE OR REPLACE FUNCTION geohash_encode(IN digits bigint, IN min_width int = 0)
  RETURNS varchar AS $$
        DECLARE
			chars char[];
			ret varchar;
			val bigint;
		BEGIN
		chars := ARRAY['0','1','2','3','4','5','6','7','8','9'
			,'b','c','d','e','f','g','h','j','k','m','n','p','q'
			,'r','s','t','u','v','w','x','y','z'];
		val := digits;
		ret := '';
		IF val < 0 THEN
			val := val * -1;
		END IF;
		WHILE val != 0 LOOP
			ret := chars[(val % 32)+1] || ret;
			val := val / 32;
		END LOOP;

		IF min_width > 0 AND char_length(ret) < min_width THEN
			ret := lpad(ret, min_width, '0');
		END IF;

		RETURN ret;
 
END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;