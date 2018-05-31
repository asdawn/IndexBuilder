/**
2D Kernel density estimation tool for PostGIS

Scripts in this files requires PostgreSQL+PostGIS
**/

--------density estimation--------






-----------standard kernels-------------

/**
Kernel_uniform(x,y,r,n)
    2D uniform kernel function.
    x - relative x in cells
    y - relative y in cells
    r - radius/bandwidth in cells, default is 2
    n - the value of the center point, default is 1
    nqsegs - segs per quater circle. 4*nqsegs segments are used to simulate a circle, the default is 25 which can make the loss lower than 1/1000 
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
        RETURN ST_Area(ST_Intersection(circle, grid))*density*n;
    END IF;
END;
$$ LANGUAGE plpgsql;


--------kernels for nav_grid--------

/**
Grid_Density
    a datatype to store density estimation result.
**/
CREATE TYPE Grid_Density AS (  
    gridid BIGINT,  
    density DOUBLE PRECISION
); 

/**
Kernel_uniform_grid(x,y,r,n)
    2D uniform kernel function, returns array of Grid_Density{gridid BIGINT, density DOUBLE PRECISION}. 
    point - point geometry
    r - radius/bandwidth in degree
    gridLevel - the gridlevel, z part of gridid
 		0 - 10m (+0.0001, +0.0001)  
		1 - 100m (+0.001, +0.001) 
		2 - 200m (+0.002, +0.002) 
		3 - reserved   
		4 - 500m (+0.005, +0.005)  
		5 - 1000m (+0.01, +0.01)
		6 - 2000m (+0.02, +0.02) 
		7 - reserved   
		8 - 5000m (+0.05, +0.05)  
		9 - 10000m (+0.1, +0.1) 
    n - the weight of the center point, default is 1
    nqsegs - segs per quater circle. 4*nqsegs segments are used to simulate a circle. The default is 25 which can make the loss lower than 1/1000 
IMPORTANT: IF point IS NOT ST_POINT OR NULL, THIS FUNCTION WILL RETURN NULL.
**/
CREATE or REPLACE FUNCTION Kernel_uniform_grid(point Geometry, r DECIMAL, gridLevel INT DEFAULT 4, n DOUBLE PRECISION DEFAULT 1) RETURNS Grid_Density[] PARALLEL SAFE COST 10000 AS $$
DECLARE
    x DECIMAL;
    y DECIMAL;
BEGIN
    IF (point IS NULL) OR (lower(ST_GeometryType(point))<>'st_point') THEN
        RETURN NULL;
    END IF;
    x := ST_X(point);
    y := ST_Y(point);
    return Kernel_uniform_grid(x, y, r, gridLevel, n);
END;
$$ LANGUAGE plpgsql;


/**
Kernel_uniform_grid(x,y,r,n)
    2D uniform kernel function, returns array of Grid_Density{gridid BIGINT, density DOUBLE PRECISION}.
    x - longitude of the point
    y - latitude of the point
    r - radius/bandwidth in degree
    gridLevel - the gridlevel, z part of gridid
 		0 - 10m (+0.0001, +0.0001)  
		1 - 100m (+0.001, +0.001) 
		2 - 200m (+0.002, +0.002) 
		3 - reserved   
		4 - 500m (+0.005, +0.005)  
		5 - 1000m (+0.01, +0.01)
		6 - 2000m (+0.02, +0.02) 
		7 - reserved   
		8 - 5000m (+0.05, +0.05)  
		9 - 10000m (+0.1, +0.1) 
    n - the weight of the center point, default is 1
    nqsegs - segs per quater circle. 4*nqsegs segments are used to simulate a circle. The default is 25 which can make the loss lower than 1/1000 
**/
CREATE or REPLACE FUNCTION Kernel_uniform_grid(x DECIMAL, y DECIMAL, r DECIMAL, gridLevel INT DEFAULT 4, n DOUBLE PRECISION DEFAULT 1) RETURNS Grid_Density[] PARALLEL SAFE COST 1000 AS $$
DECLARE
    results Grid_Density[];
    result Grid_Density;
    gridids BIGINT[];
    circle Geometry;
    grid Geometry;
    cnt INT;
    i INT; 
    iOut INT; --Output index
    density DOUBLE PRECISION;
    avgDensity DOUBLE PRECISION;
BEGIN
    IF x=NULL or y=NULL or r=NULL THEN
        RETURN NULL;
    END IF;
    avgDensity := 1.0/(PI()*r*r);
    circle := st_buffer(ST_Point(x,y), r, 24);
    gridids := v_gridid_array(circle, gridLevel);
    cnt :=  array_length( gridids,1);
    iOut := 0;
    FOR i IN 1 .. cnt LOOP
        grid := gridpolygon(gridids[i]);
        density := ST_Area(ST_Intersection(circle, grid))*avgDensity*n;
        --raise notice '% %', gridids[i], density;
        IF density>0 THEN
            iOut = iOut + 1;
            result.gridid = gridids[i];
            result.density = density;
            results[iOut]=result;
        END IF;
    END LOOP;
    return results;
END;
$$ LANGUAGE plpgsql;

/**
upsert_grid_density
    upsert the result table, that is, if there is no such gridid, insert it; if exists, update the density.
    tableName - the table to update. It must have such fields:
        gridid BIGINT PRIMARY KEY - gridID must be a primary key, because here we use upsert
        density DOUBLE PRECISION - the result field
    dvalues - Grid_Density[], data to upsert into table
    batchSize - upsert may cost time than normal insert/update, here we try to run many queries at once. the default is 100
**/
CREATE or REPLACE FUNCTION upsert_grid_density(tableName Text, dvalues Grid_Density[], batchSize INT DEFAULT 100) RETURNS boolean AS $$
DECLARE
    sql TEXT default '';
    n INT; 
    value Grid_Density;
BEGIN
    IF tableName IS NULL OR dvalues IS NULL THEN
        RETURN FALSE;
    END IF;
    n := array_length(dvalues, 1);
    FOR i IN 1 .. n LOOP   
        value = dvalues[i];
        sql := sql || 'INSERT INTO ' || tableName || '(gridid,density) values(' || value.gridid || ',' || value.density || ') on CONFLICT(gridid) DO UPDATE SET density=' || tableName ||'.density+' || value.density || ';';
        --raise notice '%', sql;
        -- execute 100 sqls at once
        IF MOD(i,batchSize)=0 OR i=n THEN
            execute sql;
            sql := '';            
        END IF;
    END LOOP;
    RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;
