/**
2D Kernel density estimation tool for PostGIS

Scripts in this files requires PostgreSQL+PostGIS
**/

--------density estimation--------










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
    circle Geometry;
    grid Geometry;
    points Geometry[];
    density DOUBLE PRECISION;
BEGIN
    density := 1.0/(PI()*r*r);
    /*
        circle is the range effected by (0,0), density is the density per 1 square unit, grid is a 1*1 unit grid whose centroid is (x,y).
        To distribute possibility into grid, here we calculate the area of st_intersection(circle, grid), and times it by density.
    */
    circle := st_buffer(ST_Point(0,0), r, nqsegs);
    --a closed path
    points[1] := ST_Point(x-0.5,y-0.5);
    points[2] := ST_Point(x+0.5, y-0.5);
    points[3] := ST_Point(x+0.5,y+0.5);
    points[4] := ST_Point(x-0.5,y+0.5);
    points[5] := ST_Point(x-0.5,y-0.5);
    grid := ST_MakePolygon(ST_MakeLine(points));   
	IF NOT ST_Intersects(circle, grid) THEN
        RETURN 0;
    ELSE
        RETURN ST_Area(ST_Intersection(circle, grid))*density;
    END IF;
END;
$$ LANGUAGE plpgsql;
