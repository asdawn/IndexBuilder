import com.navdata.kernel.Classifier100
import com.navdata.kernel.GridEstimator
import com.navinfo.grid.Grid
import com.navinfo.grid.GridLevel

import java.awt.geom.Point2D
import java.sql.DriverManager
import java.util.Hashtable.ValueCollection
import java.util.stream.SortedOps.AbstractDoubleSortingSink

import org.gdal.gdal.gdal
import org.gdal.gdalconst.gdalconst
import org.gdal.ogr.Feature
import org.gdal.ogr.FeatureDefn
import org.gdal.ogr.FieldDefn
import org.gdal.ogr.GeomFieldDefn
import org.gdal.ogr.Geometry
import org.gdal.ogr.ogr
import org.gdal.ogr.ogrConstants
import org.gdal.osr.SpatialReference
import org.gdal.osr.osr


//final 联调1
println "1"
GridEstimator e = new GridEstimator();


//input: 2 points
Point2D[] points = new Point2D[1000];
for(int i=0;i<1000;i++) {
	points[i] = new Point2D.Double(1+0.05*Math.random(), 1+0.05*Math.random())
}

println "2"
//density points
Map<Long,  Double> result = e.estimate(points, 0.015,GridLevel.GRID_0_005);
//to vector layer
ogr.RegisterAll()
gdal.AllRegister()
def dsIn = ogr.GetDriverByName("MEMORY").CreateDataSource("temp")
def wgs84 = new SpatialReference()
wgs84.ImportFromEPSG(4326)
def layer = dsIn.CreateLayer("pointdata",wgs84 , ogrConstants.wkbPoint)
def geomdef = new GeomFieldDefn();
layer.CreateGeomField(geomdef)


println "3"
////reclassify
int vn = result.keySet().size()
double[] values = new double[vn]
int idex = 0
for(Long grid: result.keySet()) {	
	def z = result.get(grid);
	values[idex] = z
	idex ++
}
Classifier100 f = new Classifier100();
int[] index = f.map(values);
////


println "4"
idex = 0
for(Long grid: result.keySet()) {
	//println Grid.getWKT(grid)
	def z = index[idex]
	def half_l = 0.0025
	def x = Grid.getX(grid)+half_l
	def y = Grid.getY(grid)+half_l		
	def feature = new Feature(layer.GetLayerDefn())
	feature.SetGeometry(Geometry.CreateFromWkt("POINT(${x} ${y} ${z})"))
	layer.CreateFeature(feature)	
	idex ++
}
layer.SyncToDisk()


println "5"
//burn to raster
def extent = layer.GetExtent()
println extent
def x0 =((int)(extent[0]*100) )/100
def y0 =((int)(extent[2]*100) )/100
println "x0=${x0}, y0=${y0}"
def xsize = (int)((extent[1]-extent[0])/0.005+4)
def ysize = (int)((extent[3]-extent[2])/0.005+4)
println "xsize=${xsize}, ysize = ${ysize}"
//def driver = gdal.GetDriverByName("GTiff")
//ds = driver.Create("c:/tmp/aa/alaala.tiff", xsize, ysize, 1, gdalconst.GDT_Float32)
def driver = gdal.GetDriverByName("MEM")
ds = driver.Create("alaala.tiff", xsize, ysize, 1, gdalconst.GDT_Float32)
def wgs84WKT = osr.SRS_WKT_WGS84
ds.SetProjection(wgs84WKT)
def double[] t = [x0, 0.005, 0, y0, 0 ,0.005]
ds.SetGeoTransform(t)
def int[] bands  =[1]
def double[] burnv = [0]
Vector<String> ops = new Vector<>()
ops.add('ALL_TOUCHED=TRUE')
ops.add("BURN_VALUE_FROM=Z")
def ok = gdal.RasterizeLayer(ds, bands, layer, burnv, ops)
ds.FlushCache()


println "6"
//get contour
def band = ds.GetRasterBand(1)
def layerOut = dsIn.CreateLayer("xxx", null, ogrConstants.wkbLineString)
def elevation = new FieldDefn("Elevation", ogrConstants.OFTInteger)
layerOut.CreateField(elevation)
gdal.ContourGenerate(band, 10, 0,  null, 0, 0, layerOut, -1, 0 )


println "7"
//output line
int n = layerOut.GetFeatureCount()
for(int i=0;i<n;i++) {
	println layerOut.GetFeature(i).GetGeometryRef().ExportToWkt()+"\t"+layerOut.GetFeature(i).GetFieldAsInteger(0)

}

//to polygon with value 
























