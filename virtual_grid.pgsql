/**
Generate grids within/intersects given geometry.

**/


v_grids

v_gridids

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
CREATE or REPLACE FUNCTION _getGridIDFromPoint(geom GEOMETRY, gridLevel INT) RETURNS BIGINT AS $$
DECLARE
    gridID BIGINT[];
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
**/
CREATE or REPLACE FUNCTION _getGridsFromGeometry(geom GEOMETRY, gridLevel INT) RETURNS BIGINT[] AS $$
DECLARE
    gridIDs BIGINT[];
    lowerleftGridID bigint;
    upperRightGridID bigint;
    xmax DECIMAL;
    ymax DECIMAL;
    xmin DECIMAL;
    ymin DECIMAL;
    gridLength DECIMAL;

BEGIN
    IF geom IS NULL THEN
        return NULL;
    END IF;
    xmax := ST_XMax(geom);
    xmin := ST_XMin(geom);
    ymax := ST_YMax(geom);
    ymin := ST_YMin(geom);



END;
$$ LANGUAGE plpgsql;




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



_getGridsFromMultiPoint





_getGridsFromLine

_getGridsFromMultiLine

_getGridsFromPolygon

_getGridsFromMultiPolygon



/*





	/**
	 * 多点转网格
	 * 
	 * @param point
	 *            2维MultiPoint {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromMultiPoint(Geometry multipoint, GridLevel level) {
		if (level == null) {
			return null;
		}
		Set<Long> grids = new HashSet<Long>();
		int n = multipoint.GetPointCount();
		for (int i = 0; i < n; i++) {
			Geometry point = multipoint.GetGeometryRef(i);
			if (point.IsEmpty()) {
				continue;
			}
			long grid = Grid.getGridID(point.GetX(), point.GetY(), level);
			grids.add(grid);
		}
		return grids.isEmpty() ? null : grids;
	}

	/**
	 * 单线转网格
	 * 
	 * @param point
	 *            2维Line类 {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromLine(Geometry line, GridLevel level) {
		return getGridsFromGeometry(line, level);
	}

	/**
	 * 多线转网格
	 * 
	 * @param point
	 *            2维MultiLineString {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromMultiLine(Geometry lines, GridLevel level) {
		return getGridsFromMultiGeometry(lines, level);
	}

	/**
	 * 单多边形转网格
	 * 
	 * @param point
	 *            2维Polygon {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromPolygon(Geometry polygon, GridLevel level) {
		return getGridsFromGeometry(polygon, level);
	}

	/**
	 * 多多边形转网格
	 * 
	 * @param point
	 *            2维MultiPolygon {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromMultiPolygon(Geometry polygons, GridLevel level) {
		return getGridsFromMultiGeometry(polygons, level);
	}

	/**
	 * 单多边形转网格
	 * 
	 * @param point
	 *            2维Polygon {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromGeometry(Geometry geometry, GridLevel level) {
		if (level == null) {
			return null;
		}
		if (geometry == null || geometry.IsEmpty()) {
			return null;
		}
		Set<Long> grids = new HashSet<Long>();
		Geometry polygon = geometry.Buffer(level.length());
		int length = (int) (level.length() * 10000);
		double[] envelope = new double[4];
		polygon.GetEnvelope(envelope);
		int xmin = (int) (envelope[0] * 10000);
		int xmax = (int) (envelope[1] * 10000);
		int ymin = (int) (envelope[2] * 10000);
		int ymax = (int) (envelope[3] * 10000);
		for (int x = xmin; x <= xmax; x += length) {
			for (int y = ymin; y <= ymax; y += length) {
				long grid = Grid.getGridID(x / 10000.0, y / 10000.0, level);
				String wkt = Grid.getWKT(grid);
				Geometry gridGeometry = WKT2Geometry.getInstance().convert(wkt);
				// 仅考虑相交的，不相交不考虑
				if (gridGeometry.Distance(geometry) == 0) {
					grids.add(grid);
				}
			}
		}
		return grids;
	}

	/**
	 * 多多边形转网格
	 * 
	 * @param point
	 *            2维MultiPolygon {@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	private static Set<Long> getGridsFromMultiGeometry(Geometry multi, GridLevel level) {
		if (level == null) {
			return null;
		}
		Set<Long> grids = new HashSet<Long>();
		int n = multi.GetGeometryCount();
		for (int i = 0; i < n; i++) {
			Geometry geometry = multi.GetGeometryRef(i);
			if (geometry.IsEmpty()) {
				continue;
			}
			Set<Long> subSet = getGridsFromGeometry(geometry, level);
			if (subSet != null && !subSet.isEmpty()) {
				grids.addAll(subSet);
			}
		}
		return grids.isEmpty() ? null : grids;
	}
}
*/




	/**
	 * 根据Geometry生成对应的网格
	 * 
	 * @param geometry
	 *            Point/MultiPoint/LineString/MultiLineString/Polygon/MultiPolygon类的{@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	public static Set<Long> getGridsFromOgrGeometry(Geometry geometry, GridLevel level) {
		return getGridsFromOgrGeometry(geometry, level, false);
	}

	/**
	 * 根据Geometry生成对应的网格
	 * 
	 * @param geometry
	 *            Point/MultiPoint/LineString/MultiLineString/Polygon/MultiPolygon类的{@link Geometry}
	 * @param level
	 *            {@link GridLevel}
	 * @param simplify
	 *            是否先简化边界，提高速度但是会有轻微误差
	 * @return gridID列表，失败或空均返回{@code null}
	 */
	public static Set<Long> getGridsFromOgrGeometry(Geometry geometry, GridLevel level, boolean simplify) {
		if (level == null || geometry == null || geometry.IsEmpty()) {
			return null;
		}
		// 按需简化，简化失败则放弃
		if (simplify) {
			Geometry simpler = geometry.Simplify(level.length() / 2);
			if (simpler != null) {
				geometry = simpler;
			}
		}
		// 判断Geometry类型
		int geometryType = geometry.GetGeometryType();
		switch (geometryType) {
		case ogrConstants.wkbPoint:
			return getGridsFromPoint(geometry, level);
		case ogrConstants.wkbMultiPoint:
			return getGridsFromMultiPoint(geometry, level);
		case ogrConstants.wkbLineString:
			return getGridsFromLine(geometry, level);
		case ogrConstants.wkbMultiLineString:
			return getGridsFromMultiLine(geometry, level);
		case ogrConstants.wkbPolygon:
			return getGridsFromPolygon(geometry, level);
		case ogrConstants.wkbMultiPolygon:
			return getGridsFromMultiPolygon(geometry, level);
		default:// 目前不考虑Curve、LinearRing、Triangle等类型
			System.err.println("Invalid geometry type.");
			return null;
		}
	}