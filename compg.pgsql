/**
Common tools
array_sort_unique: it works like SELECT DISTINCT vALUES FROM ARRAY ORDER BY VALUES and returns an array.
first: the FIRST aggregate function. It is not quite optimized, be careful when dealing with large groups. 
last: the LAST aggregate function. It is not quite optimized, be careful when dealing with large groups. 
**/

/**
array_sort_unique
    select distinct values from given array
(https://stackoverflow.com/questions/3994556/eliminate-duplicate-array-values-in-postgres)
**/
CREATE OR REPLACE FUNCTION array_sort_unique (ANYARRAY) RETURNS ANYARRAY
LANGUAGE SQL
AS $body$
  SELECT ARRAY(
    SELECT DISTINCT $1[s.i]
    FROM generate_series(array_lower($1,1), array_upper($1,1)) AS s(i)
    ORDER BY 1
  );
$body$;

/**
first and last
    postgres do not have built-in first/last functions, here is the solution
(https://wiki.postgresql.org/wiki/First/last_(aggregate))
**/
-- Create a function that always returns the first non-NULL item
CREATE OR REPLACE FUNCTION public.first_agg ( anyelement, anyelement )
RETURNS anyelement LANGUAGE SQL IMMUTABLE STRICT AS $$
        SELECT $1;
$$;
 
-- And then wrap an aggregate around it
CREATE AGGREGATE public.FIRST (
        sfunc    = public.first_agg,
        basetype = anyelement,
        stype    = anyelement
);
 
-- Create a function that always returns the last non-NULL item
CREATE OR REPLACE FUNCTION public.last_agg ( anyelement, anyelement )
RETURNS anyelement LANGUAGE SQL IMMUTABLE STRICT AS $$
        SELECT $2;
$$;
 
-- And then wrap an aggregate around it
CREATE AGGREGATE public.LAST (
        sfunc    = public.last_agg,
        basetype = anyelement,
        stype    = anyelement
);