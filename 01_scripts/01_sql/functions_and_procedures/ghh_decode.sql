CREATE OR REPLACE FUNCTION public.ghh_decode(hilbert_id bigint)
 RETURNS character varying
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
        
        DECLARE

            remainder bigint;
            hash varchar;

        BEGIN
            
            hash      := mod(hilbert_id, 4)::text;
            remainder := hilbert_id / 4;
            RAISE NOTICE 'hash: %, remainder: %', hash, remainder;
            
            WHILE remainder != 0 LOOP
                hash := mod(remainder, 4)::varchar || hash;
                remainder := remainder / 4;
                RAISE NOTICE 'hash: %, remainder: %', hash, remainder;
            END LOOP;

        RETURN hash;
 
END;
$function$
;
