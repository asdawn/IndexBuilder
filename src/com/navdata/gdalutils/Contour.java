package com.navdata.gdalutils;

import org.gdal.gdal.Band;
import org.gdal.gdal.Dataset;
import org.gdal.gdal.gdal;
import org.gdal.ogr.DataSource;
import org.gdal.ogr.FieldDefn;
import org.gdal.ogr.Layer;
import org.gdal.ogr.ogr;
import org.gdal.ogr.ogrConstants;

/**
 * Contour maker, it should be thread-safe in the future. This is a wrapper of
 * GDAl_COUNTOUR<br>
 * 
 * public static int ContourGenerate(Band srcBand, double contourInterval,
 * double contourBase, double[] fixedLevelCount, int useNoData, double
 * noDataValue, Layer dstLayer, int idField, int elevField)
 * 
 * <br>
 * here, the default band number is 1, and no data pixels will be treated as
 * normal pixels
 * 
 * @author Lin DONG
 *
 */
public class Contour {
	// init gdal and ogr
	static {
		try {
			gdal.AllRegister();
			ogr.RegisterAll();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private static int serialID = 0;

	private static synchronized String getUniqueFileName() {
		serialID++;
		return "Contour" + Thread.currentThread().getId() + "No" + serialID;
	}

	/**
	 * Extract contour from given raster layer.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @param bandNumber
	 *            the index of the band to use
	 * @param intervel
	 *            interval of contours
	 * @param base
	 *            base of contours
	 * @param seps
	 *            specify value of contours, if this is not null, intervel and base
	 *            will be ignored
	 * @param useNoDataValue
	 *            whether use no data value or ignore it
	 * @param noDataValue
	 *            specify the no data value
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour(DataSource outputVectorDataSouce, Dataset inputRaster, int bandNumber,
			double intervel, double base, double[] seps, boolean useNoDataValue, double noDataValue) {
		try {
			Band band = inputRaster.GetRasterBand(bandNumber);
			Layer result = outputVectorDataSouce.CreateLayer(getUniqueFileName(), null, ogrConstants.wkbLineString);
			FieldDefn elevation = new FieldDefn("contour", ogrConstants.OFTInteger);
			result.CreateField(elevation);
			gdal.ContourGenerate(band, intervel, base, seps, (useNoDataValue ? 1 : 0), noDataValue, result, -1, 0);
			return result;
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * Extract contour from given raster layer.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @param bandNumber
	 *            the index of the band to use
	 * @param intervel
	 *            interval of contours
	 * @param base
	 *            base of contours
	 * @param useNoDataValue
	 *            whether use no data value or ignore it
	 * @param noDataValue
	 *            specify the no data value
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour(DataSource outputVectorDataSouce, Dataset inputRaster, int bandNumber,
			double intervel, double base, boolean useNoDataValue, double noDataValue) {
		return buildContour(outputVectorDataSouce, inputRaster, bandNumber, intervel, base, null, useNoDataValue,
				noDataValue);
	}

	/**
	 * Extract contour from given raster layer.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @param intervel
	 *            interval of contours
	 * @param base
	 *            base of contours
	 * @param useNoDataValue
	 *            whether use no data value or ignore it
	 * @param noDataValue
	 *            specify the no data value
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour(DataSource outputVectorDataSouce, Dataset inputRaster, double intervel,
			double base, boolean useNoDataValue, double noDataValue) {
		return buildContour(outputVectorDataSouce, inputRaster, 1, intervel, base, null, useNoDataValue, noDataValue);
	}

	/**
	 * Extract contour from given raster layer.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @param intervel
	 *            interval of contours
	 * @param base
	 *            base of contours
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour(DataSource outputVectorDataSouce, Dataset inputRaster, double intervel,
			double base) {
		return buildContour(outputVectorDataSouce, inputRaster, 1, intervel, base, null, false, 0);
	}

	/**
	 * Extract contour from given raster layer for reclassified rasters. Base=0,
	 * interval=5, and no-data-value=0.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour100_5_0(DataSource outputVectorDataSouce, Dataset inputRaster) {
		return buildContour(outputVectorDataSouce, inputRaster, 1, 5, 0, null, true, 0);
	}

	/**
	 * Extract contour from given raster layer for reclassified rasters. Base=0,
	 * interval=10, and no-data-value=0.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour100_10_0(DataSource outputVectorDataSouce, Dataset inputRaster) {
		return buildContour(outputVectorDataSouce, inputRaster, 1, 10, 0, null, true, 0);
	}

	/**
	 * Extract contour from given raster layer for reclassified rasters. Base=20,
	 * interval=10, and no-data-value=0.
	 * 
	 * @param outputVectorDataSouce
	 * @param inputRaster
	 *            input raster
	 * @return the result layer on success, null on failure.
	 */
	public static Layer buildContour100_10_20(DataSource outputVectorDataSouce, Dataset inputRaster) {
		return buildContour(outputVectorDataSouce, inputRaster, 1, 10, 20, null, true, 0);
	}

}
