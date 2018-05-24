/*_______________________
NavGrid for PostGIS
Copyright (C) 2017 NavData, NavInfo
 ______________________*/

/*
navgrid_ver

	Get the version of this library.  
	<IMPORTANT>
	This version enabled the r digit, so it is available for the whole world. Former version in Java only support the north-east part of the earth.
*/
DROP FUNCTION if exists navgrid_ver();
CREATE FUNCTION navgrid_ver() RETURNS text AS $$
DECLARE
	version CONSTANT text := '1.0.1'  ;
BEGIN
	RETURN version;
END;
$$ LANGUAGE plpgsql;

/*
addGrid
	Add grid ID to given table. Grid ID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		tableName - name of the table.
		x_field	- name of the x(longitude) field, DEFAULT value is 'x'.
		y_field - name of the y(latitude) field, DEFAULT value is 'y'.
		gridlevel - level of grid, the z part of grid ID. DEFAULT value is 4, which means 0.005 degree or 500 meters. 
			You can get the z part by using gridlevel().
		fieldName - name of the gridID field, DEFAULT value is 'gridid'.
		addField -  whether alter table to add the field or not.
	Returns true for success, and false for failure.
	This function use Z as the grid level parameter. 
*/
DROP FUNCTION if exists addgrid(text, text, text, int, text, boolean);
CREATE FUNCTION addgrid(tableName text,  x_field text DEFAULT 'x', y_field text DEFAULT 'y', gridlevel int DEFAULT 4, 
				fieldName text DEFAULT 'gridid', addField boolean DEFAULT false) RETURNS boolean AS $$
DECLARE
	z int DEFAULT null;
	result int;
	sql text;
BEGIN
	--check params
	IF tableName is null or x_field is null or y_field is null THEN
		RAISE 'No table name or field name' USING ERRCODE = '22023';
	END IF;

	IF addField=true THEN
		sql:= 'ALTER TABLE ' ||tableName|| ' ADD COLUMN ' ||fieldName|| ' BIGINT;';
		RAISE NOTICE  'Create grid field: %', sql;
		EXECUTE sql;
	END IF;
	
	sql:='UPDATE ' ||tableName|| ' SET ' ||fieldName|| '=xy2grid(' ||x_field|| ',' ||y_field|| ',' ||gridlevel||');';
	RAISE NOTICE  'Add gridID to table: %',sql;
	EXECUTE sql;
	RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;

/*
addGrid
	Add grid ID to given table. Grid ID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		tableName - name of the table.
		x_field	- name of the x(longitude) field, DEFAULT value is 'x'.
		y_field - name of the y(latitude) field, DEFAULT value is 'y'.
		gridlengthname - norminal code for gridlevel, such as '500m', '1km'. '500m' is the default value .
		fieldName - name of the gridID field, DEFAULT value is 'gridid'.
		addField -  whether alter table to add the field or not.
	This funciton use the nominal code as the grid level parameter.		 
*/
DROP FUNCTION if exists addgrid(text, text, text, text, text, boolean);
CREATE FUNCTION addgrid(tableName text,  x_field text DEFAULT 'x', y_field text DEFAULT 'y', gridlengthname text DEFAULT '500m', 
				fieldName text DEFAULT 'gridid', addField boolean DEFAULT false) RETURNS boolean AS $$
DECLARE
	result boolean;
BEGIN
	result := addgrid(tableName, x_field, y_field,  gridlevel(gridlevel), fieldName, addField);
	RETURN result;
END;
$$ LANGUAGE plpgsql;

/*
_gridxxx
	Get the xxx part of given grid ID. Grid ID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		gridid - the input gridid
	This is a basic funtion which do not validate gridIDs.
*/
DROP FUNCTION if exists _gridxxx(bigint);
CREATE FUNCTION _gridxxx(gridid bigint) RETURNS int AS $$
DECLARE
	xxx int;
BEGIN	
	xxx := floor(gridid/100000000.0);
	RETURN xxx;
END;
$$ LANGUAGE plpgsql;


/*
_gridyyy
	Get the yyy part of given grid ID. Grid ID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		gridid - the input gridid
	This is a basic funtion which do not validate gridIDs.
*/
DROP FUNCTION if exists _gridyyy(bigint);
CREATE FUNCTION _gridyyy(gridid bigint) RETURNS int AS $$
DECLARE
	yyy int;
BEGIN
	yyy := mod(floor(gridid/100.0), 1000000);
	RETURN yyy;
END;
$$ LANGUAGE plpgsql;

/*
_gridx
	Get the x coordinate of given grid. It is the lower-left corner's x.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.
*/
DROP FUNCTION if exists _gridx(bigint);
CREATE FUNCTION _gridx(gridid bigint) RETURNS decimal(7,4) AS $$
DECLARE
	x decimal(7,4);
	r int;
	xxx int;
BEGIN
	IF (gridid is null or gridid<0) THEN
		RAISE 'Invalid gridid:  %', gridid USING ERRCODE = '22023';
	END IF;
	
	xxx := _gridxxx(gridid);
	r := _gridr(gridid);
	x := xxx/10000.0;
	
	IF r=1 OR r=2 THEN
		x =-x;
	END IF;
	
	RETURN x;
END;
$$ LANGUAGE plpgsql;

/*
_gridy
	Get the y coordinate of given grid. It is the lower-left corner's y.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.
*/
DROP FUNCTION if exists _gridy(bigint);
CREATE FUNCTION _gridy(gridid bigint) RETURNS decimal(7,4) AS $$
DECLARE
	y decimal(7,4);
	r int;
	yyy int;
BEGIN
	IF gridid is null or gridid<0 THEN
		RAISE 'Invalid gridid:  %', gridid USING ERRCODE = '22023';
	END IF;
	
	yyy := _gridyyy(gridid);
	r := _gridr(gridid);
	y := yyy/10000.0;	
	
	IF r=2 OR r=3 THEN
		y =-y;
	END IF;
	
	RETURN y;
END;
$$ LANGUAGE plpgsql;


/*
_gridz
	Get the z part of given grid ID. Z stands for the level of the grid.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.
*/
DROP FUNCTION if exists _gridz(bigint);
CREATE FUNCTION _gridz(gridid bigint) RETURNS int AS $$
DECLARE
	z int;
BEGIN
	IF gridid is null or gridid<0 THEN
		RAISE 'Invalid gridid:  %', gridid USING ERRCODE = '22023';
	END IF;
	
	z := floor(mod(gridid, 100)/10);	
	RETURN z;
END;
$$ LANGUAGE plpgsql;

/*
_gridr
	Get the r part of given grid ID. R stands for the quadrant of the grid's start point (lower-left).
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.
*/
DROP FUNCTION if exists _gridr(bigint);
CREATE FUNCTION _gridr(gridid bigint) RETURNS int AS $$
DECLARE
	r int;
BEGIN
	IF gridid is null or gridid<0 THEN
		RAISE 'Invalid gridid:  %', gridid USING ERRCODE = '22023';
	END IF;
	
	r := mod(gridid, 10);
	RETURN r;
END;
$$ LANGUAGE plpgsql;

/*

gridvalid
	Validate the given gridID. Returns true when gridid is legal, otherwise false.
		 gridid - the input gridid	
	Here null is also treated as invalid.	   
*/
DROP FUNCTION if exists gridvalid(bigint);
CREATE FUNCTION gridvalid(gridid bigint) RETURNS boolean AS $$
DECLARE
	newid bigint;
	x decimal(7,4);
	y decimal(7,4);
	z int;
BEGIN
	IF gridid is null OR gridid <0 THEN
		RETURN false;
	END IF;
	
	x := _gridx(gridid);
	y := _gridy(gridid);
	z := _gridz(gridid);
	newid := xy2grid(x,y,z);
	
	IF newid = gridid THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
EXCEPTION  
    WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;


/*
gridpolygonwkt
	Get the WKT expression of the given grid.
		 gridid - the input gridid	
	This function will return null if gridid is invalid. 	 			   
*/
DROP FUNCTION if exists gridpolygonwkt(bigint);
CREATE FUNCTION gridpolygonwkt(gridid bigint) RETURNS text AS $$
DECLARE
	xmin decimal(7,4);
	ymin decimal(7,4);
	xmax decimal(7,4);
	ymax decimal(7,4);
	wkt text;
BEGIN
	IF gridvalid(gridid)=false THEN
		RETURN null;
	END IF;	
	
	xmin := _gridxmin(gridid);
	ymin := _gridymin(gridid);
	xmax := _gridxmax(gridid);
	ymax := _gridymax(gridid);	
	--POLYGON((xmin ymin,xmax ymin,xmax ymax,xmin ymax,xmin ymin))
	wkt := 'POLYGON((' || xmin || ' ' || ymin || ',' || xmax || ' ' || ymin || ',' || xmax || ' ' || ymax || ',' || xmin || ' ' || ymax || ',' || xmin || ' ' || ymin || '))';
	
	RETURN wkt;
END;
$$ LANGUAGE plpgsql;

/*
gridpolygon
<Requires PostgreSQL+PostGIS>
	Get the polygon geometry of the grid.
 		gridid - the input gridid	
	This function will return null if gridid is invalid. 	 			   
*/
DROP FUNCTION if exists gridpolygon(bigint);
CREATE FUNCTION gridpolygon(gridid bigint) RETURNS geometry AS $$
DECLARE
	wkt text;
BEGIN
	wkt := gridpolygonwkt(gridid);
	
	IF wkt = null THEN
		RETURN null;
	END IF;	
	--requires postgis
	RETURN st_GeomFromText(wkt);
END;
$$ LANGUAGE plpgsql;


/*
gridpoint
<Requires PostgreSQL+PostGIS>
	Get the point geometry of the grid.
 		gridid - the input gridid
 		center - use the center of the grid. Otherwise use the start point (lower-left). The default value is false, which means use the start point.
	This function will return null if gridid is invalid. 	 			   
*/
DROP FUNCTION if exists gridpoint(bigint,boolean);
CREATE FUNCTION gridpoint(gridid bigint,center boolean DEFAULT false) RETURNS geometry AS $$
DECLARE
	x decimal(7,4);
	y decimal(7,4);
	length decimal(7,4);
BEGIN
	IF gridvalid(gridid)=false THEN
		RETURN null;
	END IF;
	
	x := _gridx(gridid);
	y := _gridy(gridid);	
	--Use centroid of the grid
	IF center = true THEN
		length = gridlength(gridid);
		x := x+length/2;
		y := y+length/2;
	END IF;
	--requires postgis
	RETURN ST_POINT(x,y);
END;
$$ LANGUAGE plpgsql;

/*
point2grid
<Requires PostgreSQL+PostGIS>
	Get the gridid according to the coordinate of given point.
 		point - the point 	
 		gridlevel - the gridlevel, z part of gridid
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
	This function will return null if the geometry is null. 
	An exception will be thrown if the geometry is not a point. 	 			   
*/
DROP FUNCTION if exists point2grid(geometry, int);
CREATE FUNCTION point2grid(point geometry, gridlevel int) RETURNS bigint AS $$
DECLARE
BEGIN
	IF point is null THEN
		RETURN null;
	END IF;	
	RETURN xy2grid(st_x(point), st_y(point), gridlevel);
END;
$$ LANGUAGE plpgsql;

/*
gridpointwkt
	Get the WKT expression of the point of the given grid.
		 gridid - the input gridid	
		 center - use the center of the grid. Otherwise use the start point (lower-left). The default value is false, which means use the start point.
	This function will return null if gridid is invalid. 
	This function can work without PostGIS.			   
*/
DROP FUNCTION if exists gridpointwkt(bigint,boolean);
CREATE FUNCTION gridpointwkt(gridid bigint,center boolean DEFAULT false) RETURNS text AS $$
DECLARE
	x decimal(7,4);
	y decimal(7,4);
	length decimal(7,4);
BEGIN
	IF gridvalid(gridid)=false THEN
		RETURN null;
	END IF;
	
	x := _gridx(gridid);
	y := _gridy(gridid);
	--Use centroid of the grid
	IF center = true THEN
		length = gridlength(gridid);
		x := x+length/2;
		y := y+length/2;
	END IF;
	--requires nothing
	RETURN 'POINT(' || x || ' ' || y ||')';
END;
$$ LANGUAGE plpgsql;

/*
_gridxmin
	Get the minimum x coordinate of the grid.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.   
*/
DROP FUNCTION if exists _gridxmin(bigint);
CREATE FUNCTION _gridxmin(gridid bigint) RETURNS decimal AS $$
DECLARE
BEGIN
	RETURN _gridx(gridid);
END;
$$ LANGUAGE plpgsql;

/*
_gridymin
	Get the minimum y coordinate of the grid.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.   
*/
DROP FUNCTION if exists _gridymin(bigint);
CREATE FUNCTION _gridymin(gridid bigint) RETURNS  decimal(7,4) AS $$
DECLARE
BEGIN
	RETURN _gridy(gridid);
END;
$$ LANGUAGE plpgsql;

/*
_gridxmax
Get the maximum x coordinate of the grid.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.   
*/
DROP FUNCTION if exists _gridxmax(bigint);
CREATE FUNCTION _gridxmax(gridid bigint) RETURNS decimal(7,4) AS $$
DECLARE
	xmin decimal(7,4);
	length decimal(7,4);
BEGIN
	length = gridlength(gridid);	
	IF length = null THEN
		RETURN null;
	END IF;
	
	xmin = _gridx(gridid);		
	IF xmin = null THEN
		RETURN null;
	END IF;
	
	RETURN xmin+length;
END;
$$ LANGUAGE plpgsql;

/*
_gridymax
Get the maximum y coordinate of the grid.
		gridid - the input gridid
	This is a basic funtion which do not quite validate the gridid. If there exists apparant error, it will return null.   
*/
DROP FUNCTION if exists _gridymax(bigint);
CREATE FUNCTION _gridymax(gridid bigint) RETURNS decimal(7,4) AS $$
DECLARE
	ymin decimal(7,4);
	length decimal(7,4);
BEGIN
	length = gridlength(gridid);
	IF length = null THEN
		RETURN null;
	END IF;
	
	ymin = _gridy(gridid);
	IF ymin = null THEN
		RETURN null;
	END IF;
	
	RETURN ymin+length;
END;
$$ LANGUAGE plpgsql;


/*
addGridIndex
<Requires PostgreSQL+PostGIS>
	Create index for the given field. Though it is called addGridIndex, it is a general purpose function. Name of the index is automatically generated.
	For example, name of the index for field F in table T will be FiT.  
		tableName - table to access
		fieldName - name of the field, the default value is 'gridid'
		geomField - whether its type is geometry or not. A geometry field should use GIST index.
		ifNotExists - whether to use IF NOT EXISTS in the statement or not, the default value is false.
	This function will create index on given table for given field. After the work finished, it will return ture. If there's any error, it will return false.
*/
DROP FUNCTION if exists addgridindex(text, text, boolean, boolean);
CREATE FUNCTION addgridindex(tableName text,  fieldName text DEFAULT 'gridid', geomField boolean DEFAULT false, ifNotExists boolean DEFAULT false) RETURNS boolean AS $$
DECLARE
	sql text;
BEGIN
	--check params
	IF tableName is null THEN
		RAISE 'No table name' USING ERRCODE = '22023';
	END IF;
	
	sql := 'CREATE INDEX ';
	
	IF ifNotExists THEN
		sql := sql || 'IF NOT EXISTS ';
	END IF;
	
	IF geomField = false THEN
		sql:= sql ||tableName|| 'i' ||fieldName|| ' ON ' ||tableName|| '(' ||fieldName|| ');';
	ELSE
		sql:= sql ||tableName|| 'i' ||fieldName|| ' ON ' ||tableName|| ' USING GIST(' ||fieldName|| ');';
	END IF;
	--Always show the SQL to execute
	RAISE NOTICE  'Create index: %', sql;
	EXECUTE sql;
	
	RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;

/*
dropGridIndex
	Drop index for the given field. Though it is called addGridIndex, it is a general purpose function. Name of the index is automatically generated.
	For example, name of the index for field F in table T will be FiT.  
		tableName - table to access
		fieldName - name of the field, the default value is 'gridid'
		ifNotExists - whether to use IF NOT EXISTS in the statement or not, the default value is false.
	This function will drop the given index on given table for given field. After the work finished, it will return ture. If there's any error, it will return false.
*/
DROP FUNCTION if exists dropgridindex(text, text,boolean);
CREATE FUNCTION dropgridindex(tableName text,  fieldName text DEFAULT 'gridid', ifExists boolean DEFAULT false) RETURNS boolean AS $$
DECLARE
	sql text;
BEGIN
	--check params
	IF tableName is null THEN
		RAISE 'No table name' USING ERRCODE = '22023';
	END IF;
	
	sql := 'DROP INDEX ';
	
	IF ifExists THEN
		sql := sql || 'IF EXISTS ';
	END IF;
	
	sql := sql ||tableName|| 'i' ||fieldName|| ';';
	--Always show the SQL to execute
	RAISE NOTICE  'Drop index: %', sql;
	EXECUTE sql;
	RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;

/*
_checkZ
	Check the z value of gridID.
		z - z part of gridID. 
	Returns 0 if the z value is valid, 1 otherwise.
	<IMPORTANT>
	THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 
*/
DROP FUNCTION if exists _checkZ(z int);
CREATE FUNCTION _checkZ(z int) RETURNS boolean AS $$
DECLARE
BEGIN
	IF z NOT IN(0,1,2,4,5,6,8,9) THEN
		RETURN false;
	ELSE
		RETURN true;
	END IF;
END;
$$ LANGUAGE plpgsql;

/*
xy2grid
	Get gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		z - grid level (directly use z in grid id)
	Invalid parameters will cause an exception.
		
	<IMPORTANT>
		WHAT IS A GRID
		One grid means a square in the WGS 1984 coordinate(EPSG:4326). It will be a rectangle on web maps using the Google Map Coordinate(EPSG:3857, 90013).
		We call the lower-left side of the grid "the start point of grid", and the length of side in degree "length of grid" or "grid level". 
		There are several predefined lengths of grid, shows below (the instruction of z in the instructions of gridID). 
		
	<IMPORTANT>
		WHY WE USE GRIDS
		Here we use grids to make up a fishnet which covers the whole world, as unified analyze/visualization units. For each grid level, 
		(0, 0) is the start point of the "original grid", others one by one are adjacent but not overlapped. Predefined grid level are selected carefully, 
		choosing short and meaningful decimal lengths, not simply binary divisions of 1 (0.5, 0.25, 0.125, 0.0625 is okay, how about 0.03125, 0.015625 and so on?).
		To make it easier, we take a sound alias such as "500m" (which means 500 meters) for each grid level, though not precise. 
		All kinds of fishnets shares a common start point at most every 0.1 degree. 		 
		
	<IMPORTANT>
		WHAT IS THE GRIDID OF A GRID
		GridID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		xxxxxxx: longitude of the start point, using 4 to 7 digits, keep 4 decimal places. For example, 123.12345678-->1231234.
		yyyyyy: latitude of the start point, must be 6 digits, keep 4 decimal places. For example, 1.12345678-->0121234. 
		z: grid level, here 1 degree is treated as 100000 meters to make it easy to understand.
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
		r: the quadrant flag
			0: north-east, x belongs to  [0,180] and y belongs to [0,90] 
			1: north-west, x belongs to  [-180,0) and y belongs to [0,90] 
			2: south-west, x belongs to  [-180,0) and y belongs to [-90,0) 
			3: south-est, x belongs to  [180,0] and y belongs to [-90,0) 
			
	 <IMPORTANT>
		THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 	    
*/
DROP FUNCTION if exists xy2grid(decimal, decimal, int);
CREATE FUNCTION xy2grid(x decimal, y decimal, z int) RETURNS bigint PARALLEL SAFE AS $$
DECLARE
	xxx int DEFAULT 0;
	yyy int DEFAULT 0;
	r int DEFAULT 0;
	result bigint DEFAULT null;    
BEGIN	
	--Z, 3 and 7 are reserved
	IF _checkZ(z)<>true THEN
		RAISE 'Invalid grid level: z = %', z USING ERRCODE = '22023';
    END IF;
	
	--NaN
	/* for double
    IF (x = 'Infinity' or x ='-Infinity' or x = 'NaN' or y = 'Infinity' or y ='-Infinity' or y = 'NaN') THEN
		RAISE 'Infinity or NaN coordinates: (%, %)', x,y USING ERRCODE = '22023';
    END IF;
    */
    --NULL
 	IF (x is null or y is null) THEN
   		RETURN result; -- null
   	END IF;
    --Invalid x,y
    IF (x >180 or x <-180 or y>90 or y <-90) THEN
		RAISE 'Invalid coordinates: (%, %)', x, y USING ERRCODE = '22023';
    END IF;
 
    --get xxx, yyy
   	CASE z
		WHEN 0 THEN --0.0001
			xxx := floor(x*10000);
   			yyy := floor(y*10000);
    	WHEN 1 THEN --0.001
    		xxx := floor(x*1000)*10;
   			yyy := floor(y*1000)*10;
  		WHEN 5 THEN --0.01
    		xxx := floor(x*100)*100;
   			yyy := floor(y*100)*100;
			
		WHEN 9 THEN --0.1
   			xxx := floor(x*10)*1000;
   			yyy := floor(y*10)*1000;
		WHEN 2 THEN --0.002
			xxx := floor(x*500)*20;
   			yyy := floor(y*500)*20;
		WHEN 4 THEN --0.005
			xxx := floor(x*200)*50;
   			yyy := floor(y*200)*50;
		WHEN 6 THEN --0.02			
			xxx := floor(x*50)*200;
   			yyy := floor(y*50)*200;
		WHEN 8 THEN --0.05
			xxx := floor(x*20)*500;
   			yyy := floor(y*20)*500;
   		ELSE
			RAISE 'Invalid grid level: z = %', z USING ERRCODE = '22023';
	END CASE;	
	--R and sign	
   	IF (x >= 0 and y >=0) THEN -- +  +
   		r:=0;
	ELSIF (x <0 and y >=0) THEN
   		xxx:=-xxx;
   		r:=1;
   	ELSIF (x <0 and y <0) THEN
   		xxx:=-xxx;
   		yyy:=-yyy;
   		r:=2;
   	ELSE 
   		yyy:=-yyy;
   		r:=3;
   	END IF;   	
	--xxxxxxxyyyyyyzr
   	result := xxx::bigint*100000000+yyy*100+z*10+r;   	
   	RETURN result;
END;
$$ LANGUAGE plpgsql;

/*
xy2grid
	Get gridID of the grid which the given point lies in. Grid id is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		gridlevel - a string stands for some grid level, see the table below (the strings and corresponding z values are listed).
			'10m', '0.0001', z=0
			'100m', '0.001', z=1
			'200m', '0.002', z=2
			'500m', '0.005', z=4
			'1000m', '1km', '0.01', z=5
			'2000m', '2km', '0.02', z=6
			'5000m', '5km', '0.05', z=8
			'10000m', '10km', '0.1', z=9
			To make it easy this parameter allows some informal names of grid levels, and the length in degree (as string).
	Invalid parameters will cause an exception.
*/
DROP FUNCTION if exists xy2grid(decimal, decimal, text);
CREATE FUNCTION xy2grid(x decimal, y decimal, gridlevel text) RETURNS bigint AS $$
DECLARE
	z int DEFAULT null;
	result bigint;
BEGIN
	z:=gridlevel(gridlevel);
	result:=xy2grid(x,y,z);	
	RETURN result;
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - double ver
	Get gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		z - grid level (directly use z in grid id)
	Invalid parameters will cause an exception.
		
	<IMPORTANT>
		WHAT IS A GRID
		One grid means a square in the WGS 1984 coordinate(EPSG:4326). It will be a rectangle on web maps using the Google Map Coordinate(EPSG:3857, 90013).
		We call the lower-left side of the grid "the start point of grid", and the length of side in degree "length of grid" or "grid level". 
		There are several predefined lengths of grid, shows below (the instruction of z in the instructions of gridID). 
		
	<IMPORTANT>
		WHY WE USE GRIDS
		Here we use grids to make up a fishnet which covers the whole world, as unified analyze/visualization units. For each grid level, 
		(0, 0) is the start point of the "original grid", others one by one are adjacent but not overlapped. Predefined grid level are selected carefully, 
		choosing short and meaningful decimal lengths, not simply binary divisions of 1 (0.5, 0.25, 0.125, 0.0625 is okay, how about 0.03125, 0.015625 and so on?).
		To make it easier, we take a sound alias such as "500m" (which means 500 meters) for each grid level, though not precise. 
		All kinds of fishnets shares a common start point at most every 0.1 degree. 		 
		
	<IMPORTANT>
		WHAT IS THE GRIDID OF A GRID
		GridID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		xxxxxxx: longitude of the start point, using 4 to 7 digits, keep 4 decimal places. For example, 123.12345678-->1231234.
		yyyyyy: latitude of the start point, must be 6 digits, keep 4 decimal places. For example, 1.12345678-->0121234. 
		z: grid level, here 1 degree is treated as 100000 meters to make it easy to understand.
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
		r: the quadrant flag
			0: north-east, x belongs to  [0,180] and y belongs to [0,90] 
			1: north-west, x belongs to  [-180,0] and y belongs to [0,90] 
			2: south-west, x belongs to  [-180,0] and y belongs to [-90,0] 
			3: south-est, x belongs to  [180,0] and y belongs to [-90,0] 
			
	 <IMPORTANT>
		THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 	    
*/
DROP FUNCTION if exists xy2grid(double precision, double precision, int);
CREATE FUNCTION xy2grid(x double precision, y double precision, z int) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, z);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - float ver
	Get gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		z - grid level (directly use z in grid id)
	Invalid parameters will cause an exception.
		
	<IMPORTANT>
		WHAT IS A GRID
		One grid means a square in the WGS 1984 coordinate(EPSG:4326). It will be a rectangle on web maps using the Google Map Coordinate(EPSG:3857, 90013).
		We call the lower-left side of the grid "the start point of grid", and the length of side in degree "length of grid" or "grid level". 
		There are several predefined lengths of grid, shows below (the instruction of z in the instructions of gridID). 
		
	<IMPORTANT>
		WHY WE USE GRIDS
		Here we use grids to make up a fishnet which covers the whole world, as unified analyze/visualization units. For each grid level, 
		(0, 0) is the start point of the "original grid", others one by one are adjacent but not overlapped. Predefined grid level are selected carefully, 
		choosing short and meaningful decimal lengths, not simply binary divisions of 1 (0.5, 0.25, 0.125, 0.0625 is okay, how about 0.03125, 0.015625 and so on?).
		To make it easier, we take a sound alias such as "500m" (which means 500 meters) for each grid level, though not precise. 
		All kinds of fishnets shares a common start point at most every 0.1 degree. 		 
		
	<IMPORTANT>
		WHAT IS THE GRIDID OF A GRID
		GridID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		xxxxxxx: longitude of the start point, using 4 to 7 digits, keep 4 decimal places. For example, 123.12345678-->1231234.
		yyyyyy: latitude of the start point, must be 6 digits, keep 4 decimal places. For example, 1.12345678-->0121234. 
		z: grid level, here 1 degree is treated as 100000 meters to make it easy to understand.
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
		r: the quadrant flag
			0: north-east, x belongs to  [0,180] and y belongs to [0,90] 
			1: north-west, x belongs to  [-180,0] and y belongs to [0,90] 
			2: south-west, x belongs to  [-180,0] and y belongs to [-90,0] 
			3: south-est, x belongs to  [180,0] and y belongs to [-90,0] 
			
	 <IMPORTANT>
		THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 	    
*/
DROP FUNCTION if exists xy2grid(float, float, int);
CREATE FUNCTION xy2grid(x float, y float, z int) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, z);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - int ver
	Get gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		z - grid level (directly use z in grid id)
	Invalid parameters will cause an exception.
		
	<IMPORTANT>
		WHAT IS A GRID
		One grid means a square in the WGS 1984 coordinate(EPSG:4326). It will be a rectangle on web maps using the Google Map Coordinate(EPSG:3857, 90013).
		We call the lower-left side of the grid "the start point of grid", and the length of side in degree "length of grid" or "grid level". 
		There are several predefined lengths of grid, shows below (the instruction of z in the instructions of gridID). 
		
	<IMPORTANT>
		WHY WE USE GRIDS
		Here we use grids to make up a fishnet which covers the whole world, as unified analyze/visualization units. For each grid level, 
		(0, 0) is the start point of the "original grid", others one by one are adjacent but not overlapped. Predefined grid level are selected carefully, 
		choosing short and meaningful decimal lengths, not simply binary divisions of 1 (0.5, 0.25, 0.125, 0.0625 is okay, how about 0.03125, 0.015625 and so on?).
		To make it easier, we take a sound alias such as "500m" (which means 500 meters) for each grid level, though not precise. 
		All kinds of fishnets shares a common start point at most every 0.1 degree. 		 
		
	<IMPORTANT>
		WHAT IS THE GRIDID OF A GRID
		GridID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		xxxxxxx: longitude of the start point, using 4 to 7 digits, keep 4 decimal places. For example, 123.12345678-->1231234.
		yyyyyy: latitude of the start point, must be 6 digits, keep 4 decimal places. For example, 1.12345678-->0121234. 
		z: grid level, here 1 degree is treated as 100000 meters to make it easy to understand.
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
		r: the quadrant flag
			0: north-east, x belongs to  [0,180] and y belongs to [0,90] 
			1: north-west, x belongs to  [-180,0] and y belongs to [0,90] 
			2: south-west, x belongs to  [-180,0] and y belongs to [-90,0] 
			3: south-est, x belongs to  [180,0] and y belongs to [-90,0] 
			
	 <IMPORTANT>
		THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 	    
*/
DROP FUNCTION if exists xy2grid(int, int, int);
CREATE FUNCTION xy2grid(x int, y int, z int) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, z);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - bigint ver
	Get gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		z - grid level (directly use z in grid id)
	Invalid parameters will cause an exception.
		
	<IMPORTANT>
		WHAT IS A GRID
		One grid means a square in the WGS 1984 coordinate(EPSG:4326). It will be a rectangle on web maps using the Google Map Coordinate(EPSG:3857, 90013).
		We call the lower-left side of the grid "the start point of grid", and the length of side in degree "length of grid" or "grid level". 
		There are several predefined lengths of grid, shows below (the instruction of z in the instructions of gridID). 
		
	<IMPORTANT>
		WHY WE USE GRIDS
		Here we use grids to make up a fishnet which covers the whole world, as unified analyze/visualization units. For each grid level, 
		(0, 0) is the start point of the "original grid", others one by one are adjacent but not overlapped. Predefined grid level are selected carefully, 
		choosing short and meaningful decimal lengths, not simply binary divisions of 1 (0.5, 0.25, 0.125, 0.0625 is okay, how about 0.03125, 0.015625 and so on?).
		To make it easier, we take a sound alias such as "500m" (which means 500 meters) for each grid level, though not precise. 
		All kinds of fishnets shares a common start point at most every 0.1 degree. 		 
		
	<IMPORTANT>
		WHAT IS THE GRIDID OF A GRID
		GridID is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		xxxxxxx: longitude of the start point, using 4 to 7 digits, keep 4 decimal places. For example, 123.12345678-->1231234.
		yyyyyy: latitude of the start point, must be 6 digits, keep 4 decimal places. For example, 1.12345678-->0121234. 
		z: grid level, here 1 degree is treated as 100000 meters to make it easy to understand.
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
		r: the quadrant flag
			0: north-east, x belongs to  [0,180] and y belongs to [0,90] 
			1: north-west, x belongs to  [-180,0] and y belongs to [0,90] 
			2: south-west, x belongs to  [-180,0] and y belongs to [-90,0] 
			3: south-est, x belongs to  [180,0] and y belongs to [-90,0] 
			
	 <IMPORTANT>
		THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 	    
*/
DROP FUNCTION if exists xy2grid(bigint, bigint, int);
CREATE FUNCTION xy2grid(x bigint, y bigint, z int) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, z);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - double ver
	Get gridID of the grid which the given point lies in. Grid id is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		gridlevel - a string stands for some grid level, see the table below (the strings and corresponding z values are listed).
			'10m', '0.0001', z=0
			'100m', '0.001', z=1
			'200m', '0.002', z=2
			'500m', '0.005', z=4
			'1000m', '1km', '0.01', z=5
			'2000m', '2km', '0.02', z=6
			'5000m', '5km', '0.05', z=8
			'10000m', '10km', '0.1', z=9
			To make it easy this parameter allows some informal names of grid levels, and the length in degree (as string).
	Invalid parameters will cause an exception.
*/
DROP FUNCTION if exists xy2grid(double precision, double precision, text);
CREATE FUNCTION xy2grid(x double precision, y double precision, gridlevel text) RETURNS bigint AS $$
DECLARE

BEGIN
	RETURN xy2grid(x::decimal,y::decimal,gridlevel);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - double ver
	Get gridID of the grid which the given point lies in. Grid id is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		gridlevel - a string stands for some grid level, see the table below (the strings and corresponding z values are listed).
			'10m', '0.0001', z=0
			'100m', '0.001', z=1
			'200m', '0.002', z=2
			'500m', '0.005', z=4
			'1000m', '1km', '0.01', z=5
			'2000m', '2km', '0.02', z=6
			'5000m', '5km', '0.05', z=8
			'10000m', '10km', '0.1', z=9
			To make it easy this parameter allows some informal names of grid levels, and the length in degree (as string).
	Invalid parameters will cause an exception.
*/
DROP FUNCTION if exists xy2grid(float, float, text);
CREATE FUNCTION xy2grid(x float, y float, gridlevel text) RETURNS bigint AS $$
DECLARE

BEGIN
	RETURN xy2grid(x::decimal,y::decimal,gridlevel);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - bigint ver
	Get gridID of the grid which the given point lies in. Grid id is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		gridlevel - a string stands for some grid level, see the table below (the strings and corresponding z values are listed).
			'10m', '0.0001', z=0
			'100m', '0.001', z=1
			'200m', '0.002', z=2
			'500m', '0.005', z=4
			'1000m', '1km', '0.01', z=5
			'2000m', '2km', '0.02', z=6
			'5000m', '5km', '0.05', z=8
			'10000m', '10km', '0.1', z=9
			To make it easy this parameter allows some informal names of grid levels, and the length in degree (as string).
	Invalid parameters will cause an exception.
*/
DROP FUNCTION if exists xy2grid(bigint, bigint, text);
CREATE FUNCTION xy2grid(x bigint, y bigint, gridlevel text) RETURNS bigint AS $$
DECLARE

BEGIN
	RETURN xy2grid(x::decimal,y::decimal,gridlevel);
END;
$$ LANGUAGE plpgsql;

/*
xy2grid - int ver
	Get gridID of the grid which the given point lies in. Grid id is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]
		gridlevel - a string stands for some grid level, see the table below (the strings and corresponding z values are listed).
			'10m', '0.0001', z=0
			'100m', '0.001', z=1
			'200m', '0.002', z=2
			'500m', '0.005', z=4
			'1000m', '1km', '0.01', z=5
			'2000m', '2km', '0.02', z=6
			'5000m', '5km', '0.05', z=8
			'10000m', '10km', '0.1', z=9
			To make it easy this parameter allows some informal names of grid levels, and the length in degree (as string).
	Invalid parameters will cause an exception.
*/
DROP FUNCTION if exists xy2grid(int, int, text);
CREATE FUNCTION xy2grid(x int, y int, gridlevel text) RETURNS bigint AS $$
DECLARE

BEGIN
	RETURN xy2grid(x::decimal,y::decimal,gridlevel);
END;
$$ LANGUAGE plpgsql;

/*
gridlevel
	Get the z value in gridID. Grid id is a bigint using the lower-left coordinate of the grid in the form of xxxxxxxyyyyyyzr.
		level - grid level, legal values and corresponding z values are listed below:
			'10m', '0.0001', z=0
			'100m', '0.001', z=1
			'200m', '0.002', z=2
			'500m', '0.005', z=4
			'1000m', '1km', '0.01', z=5
			'2000m', '2km', '0.02', z=6
			'5000m', '5km', '0.05', z=8
			'10000m', '10km', '0.1', z=9
*/
DROP FUNCTION if exists gridlevel(text);
CREATE FUNCTION gridlevel(level text) RETURNS int AS $$
DECLARE	 
BEGIN
	IF level is null THEN
		RAISE 'Invalid grid level:  %', level USING ERRCODE = '22023';
    END IF; 
	--lower case is suggested
    level:=lower(level);
    IF level='10m' or level='0.0001' THEN
    	RETURN 0;
    ELSIF level='100m' or level='0.001' THEN
    	RETURN 1;
    ELSIF level='200m' or level='0.002' THEN
    	RETURN 2;
    ELSIF level='500m' or level='0.005' THEN
    	RETURN 4;
    ELSIF level='1000m' or level='1km' or level='0.01' THEN
    	RETURN 5;
    ELSIF level='2000m' or level='2km' or level='0.02' THEN
    	RETURN 6;
    ELSIF level='5000m' or level='5km' or level='0.05' THEN
    	RETURN 8;
    ELSIF level='10000m' or level='10km' or level='0.1' THEN
    	RETURN 9;
    ELSE
    	RAISE 'Invalid gridlevel name:%', level USING ERRCODE = '22023';
    END IF;    
END;
$$ LANGUAGE plpgsql;


/*
_gridlength
	Get the length in degree of given z value.
		z - z value which stands for the grid level in a grid ID.
	This function will raise an exception if z is invalid.
	<IMPORTANT>
	THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 
*/
DROP FUNCTION if exists _gridlength(int);
CREATE FUNCTION _gridlength(z int) RETURNS decimal(7,4) AS $$
DECLARE	 
BEGIN
	CASE z
		WHEN 0 THEN --0.0001
			RETURN 0.0001;
		WHEN 1 THEN --0.001
			RETURN 0.001;
		WHEN 2 THEN --0.002
			RETURN 0.002;
		WHEN 4 THEN --0.005;
			RETURN 0.005;
		WHEN 5 THEN --0.01
			RETURN 0.01;
		WHEN 6 THEN --0.02
			RETURN 0.02;
		WHEN 8 THEN --0.05
			RETURN 0.05;
		WHEN 9 THEN --0.1
			RETURN 0.1;		
		ELSE
			RAISE 'Invalid grid level: z = %', z USING ERRCODE = '22023';
	END CASE;    
END;
$$ LANGUAGE plpgsql;

/*
gridlength
	Get the length in degree of given gridID.
		gridid - ID of a grid
	This function will return null if gridID is invalid.
*/
DROP FUNCTION if exists gridlength(bigint);
CREATE FUNCTION gridlength(gridid bigint) RETURNS decimal(7,4) AS $$
DECLARE	 
	z int;
	length decimal(7,4);
BEGIN
	IF gridvalid(gridid) = false THEN
		RETURN null;
	END IF;
	
	z := _gridz(gridid);
	length := _gridlength(z);
	RETURN length;
END;
$$ LANGUAGE plpgsql;

/*
gridlevelname
	Get the norminal code of the grid level.			
		gridid - ID of a grid
	This function will return null if gridID is invalid. All possible values of the code are listed below:
			'10m', which stands for 0.0001 degree
			'100m', which stands for 0.001 degree
			'200m', which stands for 0.002 degree
			'500m', which stands for 0.005 degree
			'1000m', which stands for 0.01 degree
			'2000m', which stands for 0.02 degree
			'5000m', which stands for 0.05 degree
			'10000m' which stands for 0.1 degree	
	<IMPORTANT>
	THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 
*/
DROP FUNCTION if exists gridlevelname(bigint);
CREATE FUNCTION gridlevelname(gridid bigint) RETURNS text AS $$
DECLARE	 
	z int;
BEGIN
	IF gridvalid(gridid) = false THEN
		RETURN null;
	END IF;
	
	z := _gridz(gridid);
	CASE z
		WHEN 0 THEN --0.0001
			RETURN '10m';
		WHEN 1 THEN --0.001
			RETURN '100m';
		WHEN 2 THEN --0.002
			RETURN '200m';
		WHEN 4 THEN --0.005;
			RETURN '500m';
		WHEN 5 THEN --0.01
			RETURN '1km';
		WHEN 6 THEN --0.02
			RETURN '2km';
		WHEN 8 THEN --0.05
			RETURN '5km';
		WHEN 9 THEN --0.1
			RETURN '10km';		
		ELSE
			RETURN null;
	END CASE;  
END;
$$ LANGUAGE plpgsql;

/*
gridlengthname
	Get the norminal code of the grid length.			
		length - side length of a grid.
	This function will return null if gridID is invalid. All possible values of the code  (and valid lengths) are listed below:
			'10m', which stands for 0.0001 degree
			'100m', which stands for 0.001 degree
			'200m', which stands for 0.002 degree
			'500m', which stands for 0.005 degree
			'1000m', which stands for 0.01 degree
			'2000m', which stands for 0.02 degree
			'5000m', which stands for 0.05 degree
			'10000m' which stands for 0.1 degree	
	<IMPORTANT>
	THIS FUNCTION SHOULD BE UPDATED AFTER NEW GRIDLEVEL ADDED 
*/
DROP FUNCTION if exists gridlengthname(decimal(7,4));
CREATE FUNCTION gridlengthname(length decimal(7,4)) RETURNS text AS $$
DECLARE	 
BEGIN
	CASE length
	WHEN 0.0001 THEN --0
		RETURN '10m';
	WHEN 0.001 THEN --1
		RETURN '100m';
	WHEN 0.002 THEN --2
		RETURN '200m';
	WHEN 0.005 THEN --4;
		RETURN '500m';
	WHEN 0.01 THEN --5
		RETURN '1km';
	WHEN 0.02 THEN --6
		RETURN '2km';
	WHEN 0.05 THEN --8
		RETURN '5km';
	WHEN 0.1 THEN --9
		RETURN '10km';		
	ELSE
		RETURN null;
	END CASE;  
END;
$$ LANGUAGE plpgsql;

/*
addGridPoint
<Requires PostgreSQL+PostGIS>
	Add point geomety for the grid in given table according to gridID.
		tableName - name of the table
		fieldName - name of the gridID field, DEFAULT value is 'gridid'
		addField -  whether alter table to add the field or not, the default value is false
		useCenterPoint - whether use the centroid of the grid or lower-left point, the default value is false which means to use the latter
		SRID - the SRID of the geometry, the default value is 4326, WGS 1984.
	If there's no error, true will be returned. Otherwise false.
*/
DROP FUNCTION if exists addGridPoint(text, text, text, boolean, boolean, int);
CREATE FUNCTION addGridPoint(tableName text,  gridIDField text DEFAULT 'gridid', gridPointField text DEFAULT 'geom', addField boolean DEFAULT false, useCenterPoint boolean DEFAULT false, SRID int default 4326) RETURNS boolean AS $$
DECLARE
	sql text;
BEGIN
	--check params
	IF tableName is null THEN
		RAISE 'No table name' USING ERRCODE = '22023';
	END IF;
	
	IF addField=true THEN
		sql:= 'ALTER TABLE ' ||tableName|| ' ADD COLUMN ' ||gridPointField|| ' geometry;';
		RAISE NOTICE  'Create grid point geometry field: %', sql;
		EXECUTE sql;
		sql := 'SELECT UpdateGeometrySRID(''' || tableName || ''',''' || gridPointField || ''',' || SRID ||');';
		RAISE NOTICE  'Alter SRID to EPSG:%', sql;
		EXECUTE sql;
	END IF;
	
	sql:='UPDATE ' ||tableName|| ' SET ' ||gridPointField|| '=ST_SetSRID(gridpoint(' || gridIDField || ',' || useCenterPoint || '),' || SRID ||');';
	RAISE NOTICE  'Update grid point to table: %',sql;
	EXECUTE sql;
	RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;

/*
addGridPolygon
<Requires PostgreSQL+PostGIS>
	Add/update polygon geomety for the grid in given table according to gridID.
		tableName - name of the table.
		fieldName - name of the gridID field, DEFAULT value is 'gridid'.
		addField -  whether alter table to add the field or not.	
		SRID - the SRID of the geometry, the default value is 4326, WGS 1984. 
	If there's no error, true will be returned. Otherwise false.
*/
DROP FUNCTION if exists addGridPolygon(text, text, text, boolean, int);
CREATE FUNCTION addGridPolygon(tableName text,  gridIDField text DEFAULT 'gridid', gridPointField text DEFAULT 'geom', addField boolean DEFAULT false, SRID int default 4326) RETURNS boolean AS $$
DECLARE
	sql text;
BEGIN
	--check params
	IF tableName is null THEN
		RAISE 'No table name' USING ERRCODE = '22023';
	END IF;
	
	IF addField=true THEN
		sql:= 'ALTER TABLE ' ||tableName|| ' ADD COLUMN ' ||gridPointField|| ' geometry;';
		RAISE NOTICE  'Create grid point geometry field: %', sql;
		EXECUTE sql;
		sql := 'SELECT UpdateGeometrySRID(''' || tableName || ''',''' || gridPointField || ''',' || SRID ||');';
		RAISE NOTICE  'Alter SRID to EPSG:%', sql;
		EXECUTE sql;
	END IF;
	
	sql:='UPDATE ' ||tableName|| ' SET ' ||gridPointField|| '=ST_SetSRID(gridpolygon(' || gridIDField ||  '),' || SRID ||');';
	RAISE NOTICE  'Update grid polygon to table: %',sql;
	EXECUTE sql;	
	RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;

/*//TODO
createGridnet
<Requires PostgreSQL+PostGIS>
	Create a gridnet. The SRID is 4326, WGS 1984, and use the centrod
		tableName - name of the table		
		gridLevel - level of the grid
		
		
	If there's no error, true will be returned. Otherwise false.
*/
DROP FUNCTION if exists createGridnet(text, text, text, boolean, boolean, int);
CREATE FUNCTION createGridnet(tableName text,  gridIDField text DEFAULT 'gridid', gridPointField text DEFAULT 'geom', addField boolean DEFAULT false, useCenterPoint boolean DEFAULT false, SRID int default 4326) RETURNS boolean AS $$
DECLARE
	sql text;
BEGIN
	--check params
	IF tableName is null THEN
		RAISE 'No table name' USING ERRCODE = '22023';
	END IF;
	
	IF addField=true THEN
		sql:= 'ALTER TABLE ' ||tableName|| ' ADD COLUMN ' ||gridPointField|| ' geometry;';
		RAISE NOTICE  'Create grid point geometry field: %', sql;
		EXECUTE sql;
		sql := 'SELECT UpdateGeometrySRID(''' || tableName || ''',''' || gridPointField || ''',' || SRID ||');';
		RAISE NOTICE  'Alter SRID to EPSG:%', sql;
		EXECUTE sql;
	END IF;
	
	sql:='UPDATE ' ||tableName|| ' SET ' ||gridPointField|| '=ST_SetSRID(gridpoint(' || gridIDField || ',' || useCenterPoint || '),' || SRID ||');';
	RAISE NOTICE  'Update grid point to table: %',sql;
	EXECUTE sql;
	RETURN true;
EXCEPTION
	WHEN   OTHERS   THEN
    	RETURN false;
END;
$$ LANGUAGE plpgsql;

/*wrappers*/
/*
grid10m
	Get 0.0001 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10m(decimal, decimal);
CREATE FUNCTION grid10m(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y, 0);
END;
$$ LANGUAGE plpgsql;

/*
grid10m - float ver
	Get 0.0001 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10m(float, float);
CREATE FUNCTION grid10m(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 0);
END;
$$ LANGUAGE plpgsql;

/*
grid10m - double ver
	Get 0.0001 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10m(double precision, double precision);
CREATE FUNCTION grid10m(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 0);
END;
$$ LANGUAGE plpgsql;

/*
grid100m
	Get 0.001 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid100m(decimal, decimal);
CREATE FUNCTION grid100m(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y, 1);
END;
$$ LANGUAGE plpgsql;

/*
grid100m - float ver
	Get 0.001 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid100m(float, float);
CREATE FUNCTION grid100m(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 1);
END;
$$ LANGUAGE plpgsql;

/*
grid100m - double ver
	Get 0.001 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid100m(double precision, double precision);
CREATE FUNCTION grid100m(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 1);
END;
$$ LANGUAGE plpgsql;


/*
grid200m
	Get 0.002 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid200m(decimal, decimal);
CREATE FUNCTION grid200m(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y, 2);
END;
$$ LANGUAGE plpgsql;

/*
grid200m - float ver
	Get 0.002 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid200m(float, float);
CREATE FUNCTION grid200m(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 2);
END;
$$ LANGUAGE plpgsql;

/*
grid200m - double ver
	Get 0.021 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid200m(double precision, double precision);
CREATE FUNCTION grid200m(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 2);
END;
$$ LANGUAGE plpgsql;

/*
grid500m
	Get 0.005 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid500m(decimal, decimal);
CREATE FUNCTION grid500m(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y, 4);
END;
$$ LANGUAGE plpgsql;

/*
grid500m - float ver
	Get 0.005 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid500m(float, float);
CREATE FUNCTION grid500m(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 4);
END;
$$ LANGUAGE plpgsql;

/*
grid500m - double ver
	Get 0.005 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid500m(double precision, double precision);
CREATE FUNCTION grid500m(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 4);
END;
$$ LANGUAGE plpgsql;

/*
grid1km
	Get 0.01 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid1km(decimal, decimal);
CREATE FUNCTION grid1km(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y, 5);
END;
$$ LANGUAGE plpgsql;

/*
grid1km - float ver
	Get 0.01 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid1km(float, float);
CREATE FUNCTION grid1km(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 5);
END;
$$ LANGUAGE plpgsql;

/*
grid1km - double ver
	Get 0.01 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid1km(double precision, double precision);
CREATE FUNCTION grid1km(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 5);
END;
$$ LANGUAGE plpgsql;

/*
grid2km
	Get 0.02 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid2km(decimal, decimal);
CREATE FUNCTION grid2km(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y, 6);
END;
$$ LANGUAGE plpgsql;

/*
grid2km - float ver
	Get 0.02 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid2km(float, float);
CREATE FUNCTION grid2km(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 6);
END;
$$ LANGUAGE plpgsql;

/*
grid2km - double ver
	Get 0.02 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid2km(double precision, double precision);
CREATE FUNCTION grid2km(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 6);
END;
$$ LANGUAGE plpgsql;

/*
grid5km
	Get 0.05 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid5km(decimal, decimal);
CREATE FUNCTION grid5km(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y,8);
END;
$$ LANGUAGE plpgsql;

/*
grid5km - float ver
	Get 0.05 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid5km(float, float);
CREATE FUNCTION grid5km(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 8);
END;
$$ LANGUAGE plpgsql;

/*
grid5km - double ver
	Get 0.05 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid5km(double precision, double precision);
CREATE FUNCTION grid5km(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 8);
END;
$$ LANGUAGE plpgsql;

/*
grid10km
	Get 0.1 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10km(decimal, decimal);
CREATE FUNCTION grid10km(x decimal, y decimal) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x, y,9);
END;
$$ LANGUAGE plpgsql;

/*
grid10km - float ver
	Get 0.1 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10km(float, float);
CREATE FUNCTION grid10km(x float, y float) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 9);
END;
$$ LANGUAGE plpgsql;

/*
grid10km - double ver
	Get 0.1 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10km(double precision, double precision);
CREATE FUNCTION grid10km(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 9);
END;
$$ LANGUAGE plpgsql;

/*
grid10km - double ver
	Get 0.1 degree gridID of the grid which the given point lies in.
		x - longitude of a point, x belongs to [-180, 180]
		y - latitude of a point, y belongs to [-90, 90]		
	Invalid parameters will cause an exception.    
*/
DROP FUNCTION if exists grid10km(double precision, double precision);
CREATE FUNCTION grid10km(x double precision, y double precision) RETURNS bigint AS $$
DECLARE
BEGIN	
   	RETURN xy2grid(x::decimal, y::decimal, 9);
END;
$$ LANGUAGE plpgsql;


------since 1.0.1--------
/*
gid2geom - 
	Get the geometry of given grid ID. 
	gridid - grid ID
	point - return a point or a polygon, the default is false, that means return the grid polygon
	center - whether use the centroid a the grid or the lower-left of the grid, the default is false, 
			that means return the lower-left corner of the grid. This parameter is valid only when 
			the point parameter is true 
*/
DROP FUNCTION if exists gid2geom(BIGINT, boolean, boolean);
CREATE FUNCTION gid2geom(gridid BIGINT, point BOOLEAN DEFAULT FALSE, center BOOLEAN DEFAULT FALSE) RETURNS Geometry AS $$
DECLARE
BEGIN
	IF gridid IS NULL THEN
		RETURN NULL;
	END IF;
	IF point = TRUE THEN
		RETURN gridpoint(gridid, center);
	ELSE
		RETURN gridpolygon(gridid);	
	END IF;   	
END;
$$ LANGUAGE plpgsql;

/*
gids2geoms - 
	Get the geometries of given grid IDs. Each geometry is stored as a row.
	gridids - gridid in BIGINT ARRAY
	point - return a point or a polygon, the default is false, that means return the grid polygon
	center - whether use the centroid a the grid or the lower-left of the grid, the default is false, 
			that means return the lower-left corner of the grid. This parameter is valid only when 
			the point parameter is true 
*/
DROP FUNCTION if exists gids2geoms(BIGINT[], boolean, boolean);
CREATE FUNCTION gids2geoms(gridids BIGINT[], point BOOLEAN  DEFAULT FALSE, center BOOLEAN DEFAULT FALSE) RETURNS TABLE (geom Geometry) AS 
$$ SELECT gid2geom(unnest, point, center) FROM unnest(gridids)$$ 
LANGUAGE sql;