package com.navdata.gdalutils;

import org.gdal.gdal.Dataset;
import org.gdal.gdal.Driver;
import org.gdal.gdal.gdal;
import org.gdal.gdalconst.gdalconst;
import org.gdal.ogr.DataSource;
import org.gdal.ogr.Layer;
import org.gdal.ogr.ogr;
import org.gdal.osr.SpatialReference;
import org.gdal.osr.osr;

/**
 * Create a temporary in-memory raster data-set.
 * 
 * @author Lin DONG
 *
 */
public class MemData {

	// init gdal and ogr
	static {
		try {
			gdal.AllRegister();
			ogr.RegisterAll();
			SpatialReference defaultSR = new SpatialReference();
			defaultSR.ImportFromEPSG(4326);
			WGS84 = defaultSR;
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private final static Driver RASTER_DRIVER = gdal.GetDriverByName("MEM");
	private final static org.gdal.ogr.Driver VECTOR_DRIVER = ogr.GetDriverByName("MEMORY");
	private static int serialID = 0;
	private final static String WGS84WKT = osr.SRS_WKT_WGS84;
	private final static int FLOAT32 = gdalconst.GDT_Float32;
	private static SpatialReference WGS84;
	private final static DataSource VECTOR_DS = VECTOR_DRIVER.CreateDataSource("temp");
	
	private static synchronized String getUniqueFileName() {
		serialID++;
		return "MemoryDS" + Thread.currentThread().getId() + "No" + serialID;
	}

	/**
	 * Create a raster dataset in memory. Remember to delete it after use.
	 * 
	 * @param name
	 *            name of dataset, should be unique
	 * @param width
	 *            width of dataset
	 * @param height
	 *            height of dataset
	 * @param bands
	 *            band count of dataset
	 * @param pixelType
	 *            pixel type of dataset
	 * @param projection
	 *            WKT projection
	 * @param transform
	 *            transform parameters of dataset
	 * 
	 * @return dataset on success, null on failure.
	 */
	public synchronized static Dataset createDataset(String name, int width, int height, int bands, int pixelType,
			String projection, double[] transform) {
		Dataset result = null;
		try {
			result = RASTER_DRIVER.Create(name, width, height, bands, pixelType);
			result.SetProjection(projection);
			result.SetGeoTransform(transform);
			return result;
		} catch (Exception e) {
			e.printStackTrace();
			try {
				if (result != null) {
					result.delete();
				}
			} catch (Exception ein) {
				ein.printStackTrace();
			}
			return null;
		}
	}

	/**
	 * Create a temporary raster dataset in memory. Remember to delete it after use. <br>
	 * name=automatic name, projection=WGS84, bands=1, pixelType=FLOAT32
	 * 
	 * @param name
	 *            name of dataset, should be unique
	 * @param width
	 *            width of dataset
	 * @param height
	 *            height of dataset
	 * @param transform
	 *            transform parameters of dataset
	 * 
	 * @return dataset on success, null on failure.
	 */
	public synchronized static Dataset createTempDataset(int width, int height, double[] transform) {
		Dataset result = null;
		try {
			result = RASTER_DRIVER.Create(getUniqueFileName(), width, height, 1, FLOAT32);
			result.SetProjection(WGS84WKT);
			result.SetGeoTransform(transform);
			return result;
		} catch (Exception e) {
			e.printStackTrace();
			try {
				if (result != null) {
					result.delete();
				}
			} catch (Exception ein) {
				ein.printStackTrace();
			}
			return null;
		}
	}
	
	/**
	 * Create a vector layer in given datasource.
	 * @param dataSource output datasource
	 * @param name name of layer
	 * @param sr spatial reference
	 * @param geomType geometry type
	 * @return the layer on success, null on failure.
	 */
	public synchronized static Layer createLayer(DataSource dataSource, String name, SpatialReference sr, int geomType) {
		try {
			Layer layer = dataSource.CreateLayer(name, sr, geomType);
			return layer;
		}catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}
	
	/**
	 * Create a temporary vector layer in memory.
	 * @param sr spatial reference
	 * @param geomType geometry type
	 * @return the layer on success, null on failure.
	 */
	public synchronized static Layer createTempLayer(SpatialReference sr, int geomType) {
		return createLayer(VECTOR_DS, getUniqueFileName(), sr, geomType);
	}
	
	/**
	 * Create a temporary vector layer in memory.
	 * @param geomType geometry type
	 * @return the layer on success, null on failure.
	 */
	public synchronized static Layer createTempLayer(int geomType) {
		return createLayer(VECTOR_DS, getUniqueFileName(), WGS84, geomType);
	}

}
