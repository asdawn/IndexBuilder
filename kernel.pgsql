/**
2D Kernel density estimation tool for PostGIS

Scripts in this files requires PostgreSQL+PostGIS
**/

--------------kernels-------------
/*
IMPORTANT PARAMETERS
r: radius/bandwidth in cells, default is 2
n: the value of the center point, default is 1
x: relative x in cells
y: relative y in cells
*/
/**
Kernel_uniform(x,y,r,n)
2D uniform kernel function
nqsegs: segs per quater circle. 4*nqsegs segments are used to simulate a circle.
**/
CREATE or REPLACE FUNCTION Kernel_uniform(x INT, y INT, r DOUBLE PRECISION DEFAULT 2, n DOUBLE PRECISION DEFAULT 1, nqsegs INT DEFAULT 25) RETURNS double precision AS $$
DECLARE
    d DOUBLE PRECISION;
    absX DOUBLE PRECISION;
    absY double PRECISION;
    density DOUBLE PRECISION;
BEGIN
    density = 1.0/(PI()*r*r);


    absX := ABS(X);
    absY := ABS(Y);
	IF absX>r OR absY>r THEN
        RETURN 0;
    ELSIF absX<=r AND absY<=r THEN
        density = 1.0/(r*r);
    ELSEIF absX>r AND absY <=r


        RETURN density;
    END IF;
END;
$$ LANGUAGE plpgsql;
