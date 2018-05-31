/**
Contour builder
Copyright (C) 2018 NavData, NavInfo
**/

/**
contour_polygon
    Convert contour lines to polygons, holes will be properly made to avoid overlaps. It will try to create a spatial index on geomIn.
    contourTable - name of the input contour table, the geometries should be simple linestrings
    polygonTable - name of the output polygon table, the geometries will be polygons with holes
    geomIn - name of the geometry field in contourTable, the default value is 'geom'
    geomOut - name of the geometry field in polygonTable, the default value is 'geom'
    valueIn - name of the contour value field in contourTable, the default value is 'contour'
    valueOut - name of the contour value field in polygonTable, the default value is 'contour' 
TIPS:
    This funciton allows non-ring contours, so you don't have to clean them mannualy. However, you should make it simple. Shp2pgsql will 
convert a LINESTRING into a MUILTILINESTRING whether it is simple or not. You can use ST_CollectionHomogenize to update the table.
**/
CREATE or REPLACE FUNCTION contour_polygon(contourTable text, polygonTable text, geomIn TEXT DEFAULT 'geom', geomOut TEXT DEFAULT 'geom', valueIn TEXT DEFAULT 'contour', valueOut TEXT DEFAULT 'contour') RETURNS BOOLEAN AS $$
DECLARE
    sql text;
    cur REFCURSOR;
    cur2 REFCURSOR;
    geom Geometry;
    holes Geometry DEFAULT NULL;
    contour DOUBLE PRECISION;
    cnt INT DEFAULT 0;
BEGIN
    --ensure spatial index
    sql := 'create index if not exists ' || contourTable || 'gindex' || ' on ' || contourTable || ' using gist(' || geomIn || ');';
    EXECUTE sql;
    --some contour algorithm will create non-ring lines
    sql := 'select ' || geomIn || ',' || valueIn || ' from ' || contourTable || ' where st_isring(' || geomIn || ');';
    OPEN cur FOR EXECUTE sql;
    FETCH cur INTO geom, contour;
    WHILE found LOOP
        IF geom IS NOT NULL THEN
            geom := ST_MakePolygon(geom);
            --check if there are holes. If any, burn it.
            sql := 'select st_union(ST_MakePolygon(' || geomIn || ')) from ' || contourTable || ' where st_within(' || geomIn || ',''' || geom::text || '''::Geometry) and st_isring(' || geomIn || ');';
            OPEN cur2 FOR EXECUTE sql;
                FETCH cur2 INTO holes;
            CLOSE cur2;           
            IF found AND holes IS NOT NULL THEN
                --raise notice '%',st_astext(holes);  
                geom := ST_Difference(geom, holes);
                holes := NULL;
            END IF;
            --write into the new table
            sql := 'insert into ' || polygonTable  || '(' || geomOut || ',' || valueOut || ') values('''  || geom::text || '''::geometry, ' || contour || ');';
            --raise notice '%',sql;
            EXECUTE sql;
            cnt := cnt + 1;
            IF MOD(cnt, 10)=0 THEN -- give a response every 10 polygons
                RAISE NOTICE '% contour polygons written.', cnt;
            END IF;
        ELSE
            RAISE NOTICE '%', 'Empty or non-closed linestring, skipped.';
        END IF;
        FETCH cur INTO geom, contour;
    END LOOP;  
    CLOSE cur;
    RETURN true;
EXCEPTION WHEN others THEN
    RAISE NOTICE 'Failed to create contour: %', SQLERRM;
    RETURN false;
END;
$$ LANGUAGE plpgsql;
