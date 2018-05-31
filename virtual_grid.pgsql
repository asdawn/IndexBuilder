/**
Generate grids within/intersects given geometry.
Copyright (C) 2018 NavData, NavInfo
**/

/**
v_gridid_array
    get gridIDs according to given geometry and grid level. 
    geom - a geometry
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
    within - whether the grids generated should be within the given geometry or just intersect it. 
             The default value is false, which is valid for all types of geometries
**/
DROP FUNCTION if exists v_gridid_array(GEOMETRY,INT, BOOLEAN);
CREATE FUNCTION v_gridid_array(geom GEOMETRY, gridLevel INT, within BOOLEAN DEFAULT FALSE) RETURNS BIGINT[] AS $$
DECLARE
   geomType text;
BEGIN
    IF geom IS NULL THEN
        return NULL;
    END IF;
    geomType = lower(ST_GeometryType(geom));
    --if it is point or multipoint, it is faster to use
	CASE geomType
		WHEN 'st_point' THEN
			RETURN _getGridIDFromPoint(geom, gridLevel);
		WHEN 'st_linestring' THEN			
			RETURN _getGridsFromMultiPoint(geom, gridLevel);
		ELSE
			RETURN _getGridsFromGeometry(geom, gridLevel, within);     
	END CASE;
END;
$$ LANGUAGE plpgsql;

/**
v_gridwkt_set
    get grids(as WKTs) according to given geometry and grid level, each gridid as a row 
    geom - a geometry
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
    within - whether the grids generated should be within the given geometry or just intersect it. 
             The default value is false, which is valid for all types of geometries
    point - return a point or a polygon, the default is false, that means return the grid polygon
	center - whether use the centroid a the grid or the lower-left of the grid, the default is false, 
			that means return the lower-left corner of the grid. This parameter is valid only when 
			the point parameter is true 
**/
DROP FUNCTION if exists v_gridwkt_set(GEOMETRY, INT, BOOLEAN, BOOLEAN, BOOLEAN);
CREATE FUNCTION v_gridwkt_set(geom GEOMETRY, gridLevel INT, within BOOLEAN DEFAULT FALSE,  point BOOLEAN  DEFAULT FALSE, center BOOLEAN DEFAULT FALSE) RETURNS TABLE (gridid TEXT) AS
$$ SELECT ST_AsText(gids2geoms) FROM gids2geoms(v_gridid_array(geom, gridLevel, within), point, center) $$
LANGUAGE SQL;

/**
v_gridgeom_set
    get grids(as geometries) according to given geometry and grid level, each gridid as a row 
    geom - a geometry
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
    within - whether the grids generated should be within the given geometry or just intersect it. 
             The default value is false, which is valid for all types of geometries
    point - return a point or a polygon, the default is false, that means return the grid polygon
	center - whether use the centroid a the grid or the lower-left of the grid, the default is false, 
			that means return the lower-left corner of the grid. This parameter is valid only when 
			the point parameter is true 
**/
DROP FUNCTION if exists v_gridgeom_set(GEOMETRY, INT, BOOLEAN, BOOLEAN, BOOLEAN);
CREATE FUNCTION v_gridgeom_set(geom GEOMETRY, gridLevel INT, within BOOLEAN DEFAULT FALSE,  point BOOLEAN  DEFAULT FALSE, center BOOLEAN DEFAULT FALSE) RETURNS TABLE (gridid Geometry) AS
$$ SELECT * FROM gids2geoms(v_gridid_array(geom, gridLevel, within), point, center) $$
LANGUAGE SQL;

/**
v_gridid_set
    get gridIDs according to given geometry and grid level, each gridid as a row 
    geom - a geometry
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
    within - whether the grids generated should be within the given geometry or just intersect it. 
             The default value is false, which is valid for all types of geometries
**/
DROP FUNCTION if exists v_gridid_set(GEOMETRY, INT, BOOLEAN);
CREATE FUNCTION v_gridid_set(geom GEOMETRY, gridLevel INT, within BOOLEAN DEFAULT FALSE) RETURNS TABLE (gridid BIGINT) AS
$$ SELECT * FROM UNNEST(v_gridid_array(geom, gridLevel, within)) $$
LANGUAGE SQL;

/**
_getGridIDFromPoint
    get a gridID according to given Point and grid level. 
    geom - a Point geometry
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
**/
DROP FUNCTION if exists _getGridIDFromPoint(GEOMETRY, INT);
CREATE FUNCTION _getGridIDFromPoint(geom GEOMETRY, gridLevel INT) RETURNS BIGINT AS $$
DECLARE
    gridID BIGINT;
BEGIN
    IF geom IS NULL THEN
        return NULL;
    END IF;
    gridID := point2grid(geom, gridLevel);
    RETURN gridID;
END;
$$ LANGUAGE plpgsql;

/**
_getGridsFromMultiPoint
    get gridIDs according to given MiltiPoint and grid level. 
    geom - a Point geometry
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
**/
DROP FUNCTION if exists _getGridsFromMultiPoint(GEOMETRY, INT);
CREATE or REPLACE FUNCTION _getGridsFromMultiPoint(geom GEOMETRY, gridLevel INT) RETURNS BIGINT[] AS $$
DECLARE
    gridIDs BIGINT[];
    point Geometry;
    n INT;
    i INT;
BEGIN
    IF geom IS NULL THEN
        return NULL;
    END IF;
    n := ST_NumGeometries(geom);
    FOR i IN 1 .. n LOOP
        point := ST_GeometryN(geom, i);
        gridIDs[i] :=  _getGridIDFromPoint(point,gridLevel);
    END LOOP;
    RETURN array_sort_unique(gridIDs);
END;
$$ LANGUAGE plpgsql;

/**
_getGridsFromGeometry
    get gridIDs according to given geometry and grid level. 
    geom - a Line geometry
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
    within - whether the grids generated should be within the given geometry or just intersect it. 
             The default value is false, which is valid for all types of geometries
**/
DROP FUNCTION if exists _getGridsFromGeometry(GEOMETRY, INT, BOOLEAN);
CREATE FUNCTION _getGridsFromGeometry(geom GEOMETRY, gridLevel INT, within BOOLEAN DEFAULT FALSE) RETURNS BIGINT[] AS $$
DECLARE
    gridIDs BIGINT[];
    lowerleftGridID bigint;
    upperRightGridID bigint;
    xmax DECIMAL;
    ymax DECIMAL;
    xmin DECIMAL;
    ymin DECIMAL;
    gridLength DECIMAL;
    x DECIMAL;
    y DECIMAL;
    cnt INT;
    gridID BIGINT;
    grid GEOMETRY;
BEGIN
    IF geom IS NULL THEN
        return NULL;
    END IF;
    xmax := ST_XMax(geom);
    xmin := ST_XMin(geom);
    ymax := ST_YMax(geom);
    ymin := ST_YMin(geom);
    lowerleftGridID := xy2grid(xmin, ymin, gridLevel);
    upperRightGridID := xy2grid(xmax, ymax, gridLevel);
    gridLength := gridLength(lowerleftGridID);    
    --update x/y max/min
    xmax := _gridXMax(upperRightGridID)+gridLength;
    ymax := _gridYMax(upperRightGridID)+gridLength;    
    ymin := _gridXMin(lowerleftGridID);
    ymin := _gridYMin(lowerleftGridID);
    cnt := 0;
    x := xmin;
    <<xloop>>   
    WHILE x <= xmax LOOP       
        y := ymin;        
        <<yloop>>
        WHILE y <= ymax LOOP           
            gridID :=  xy2grid(x, y, gridLevel);            
            grid := gridpolygon(gridID);
            IF within=TRUE THEN                
                IF ST_Within(grid, geom) THEN
                    --raise notice '%', st_astext(grid);
                    cnt := cnt + 1;
                    gridIDs[cnt] := gridID;
                END IF;
            ELSE
                IF ST_Intersects(grid, geom) THEN
                    cnt := cnt + 1;
                    gridIDs[cnt] := gridID;
                END IF;
            END IF; 
            y := y+gridLength;             
        END LOOP yloop;
        x := x+gridLength;      
    END LOOP xloop;
    RETURN array_sort_unique(gridIDs);
END;
$$ LANGUAGE plpgsql;


