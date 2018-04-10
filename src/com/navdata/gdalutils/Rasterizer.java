package com.navdata.gdalutils;

import java.util.Vector;
import org.gdal.gdal.Dataset;
import org.gdal.gdal.gdal;
import org.gdal.ogr.Layer;
import org.gdal.ogr.ogr;

import com.navinfo.grid.GridLevel;

/**
 * Rasterize given vector layer.
 * 
 * @author Lin DONG
 *
 */
public class Rasterizer {
	final static Vector<String> OPTIONS = new Vector<>();
	final static double[] BURNV = { 0 };
	final static int[] BANDS = { 1 };
	static {
		OPTIONS.add("ALL_TOUCHED=TRUE");
		OPTIONS.add("BURN_VALUE_FROM=Z");
		// init gdal and ogr
		try {
			gdal.AllRegister();
			ogr.RegisterAll();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	/**
	 * Rasterize given layer, the boundary will be automatically calculated (may be
	 * a little larger), grid size is given by GridLevel.
	 * 
	 * @param inputLayer
	 *            input vector layer
	 * @param level
	 *            pixcel size as {@link GridLevel}
	 * @return the result dataset on sucess, null on failure.
	 */
	public static Dataset rasterize(Layer inputLayer, GridLevel level) {
		try {
			double[] extent = inputLayer.GetExtent();
			double length = level.length();
			int reciprocal = (int) Math.round(1 / length);
			double x0 = Math.floor(extent[0] * reciprocal) / reciprocal;
			double y0 = Math.floor(extent[2] * reciprocal) / reciprocal;
			double x1 = extent[1];
			double y1 = extent[3];
			int xsize = (int) ((x1 - x0) / length + 2);
			int ysize = (int) ((y1 - y0) / length + 2);
			double[] transform = { x0, length, 0, y0, 0, length };
			Dataset outputRaster = MemData.createTempDataset(xsize, ysize, transform);
			/*
			 * Driver driver = gdal.GetDriverByName("GTiff"); Dataset outputRaster =
			 * driver.Create("c:/tmp/aa/a1.tiff", xsize, ysize, 1, gdalconst.GDT_Float32);
			 * String wgs84WKT = osr.SRS_WKT_WGS84; outputRaster.SetProjection(wgs84WKT);
			 * outputRaster.SetGeoTransform(transform); Dataset outputRaster =
			 * 
			 */
			gdal.RasterizeLayer(outputRaster, BANDS, inputLayer, BURNV, OPTIONS);
			outputRaster.FlushCache();
			return outputRaster;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}
}
