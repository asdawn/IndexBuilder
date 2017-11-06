package com.navdata.kernel;

import java.awt.geom.Point2D;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.gdal.ogr.Geometry;

import com.navdata.kernel.base.Kernel2D;
import com.navdata.kernel.base.UniformKernel2D;
import com.navinfo.grid.Grid;
import com.navinfo.grid.GridLevel;
import com.navinfo.grid.VirtualGrid;

/**
 * 2D Kernel density estimator
 * 
 * @author Lin DONG
 *
 */
public class GridEstimator {
	
	private static final Kernel2D K = new UniformKernel2D();

	/**
	 * Calculate expectation in grids
	 * 
	 * @param points
	 *            points with a weight/population as the input
	 * @param bandWidth
	 *            band width, the effective range of the kernel function
	 * @param gridLevel
	 *            size of grid, {@link GridLevel}. The default value is
	 *            {@link GridLevel.GRID_0_005}
	 * @return the result in a {@link Map}, gridID to expectation
	 */
	Map<Long, Double> estimate(Map<Point2D, Double> points, double bandWidth, GridLevel gridLevel) {
		Map<Long, Double> result = new HashMap<>();
		for (Point2D point : points.keySet()) {
			Double n = points.get(point);
			updateMap(result, point, n, bandWidth, gridLevel);
		}
		return result.isEmpty() ? null : result;
	}

	/**
	 * Estimate the density in grids
	 * 
	 * @param points
	 *            points as the input
	 * @param bandWidth
	 *            band width, the effective range of the kernel function
	 * @param gridLevel
	 *            size of grid, {@link GridLevel}
	 * @return the result in a {@link Map}, gridID to density
	 */
	Map<Long, Double> estimate(Collection<Point2D> points, double bandWidth, GridLevel gridLevel) {
		Map<Long, Double> result = new HashMap<>();
		for (Point2D point : points) {
			updateMap(result, point, null, bandWidth, gridLevel);
		}
		return result.isEmpty() ? null : result;
	}

	/**
	 * Estimate the density in grids
	 * 
	 * @param points
	 *            points as the input
	 * @param bandWidth
	 *            band width, the effective range of the kernel function
	 * @return the result in a {@link Map}, gridID to density
	 */
	Map<Long, Double> estimate(Collection<Point2D> points, double bandWidth) {
		Map<Long, Double> result = new HashMap<>();
		for (Point2D point : points) {
			updateMap(result, point, null, bandWidth, null);
		}
		return result.isEmpty() ? null : result;
	}

	/**
	 * Estimate the density in grids
	 * 
	 * @param points
	 *            points points as the input
	 * @param bandWidth
	 *            band width, the effective range of the kernel function
	 * @param gridLevel
	 *            size of grid, {@link GridLevel}
	 * @return the result in a {@link Map}, gridID to density
	 */
	Map<Long, Double> estimate(Point2D[] points, double bandWidth, GridLevel gridLevel) {
		Map<Long, Double> result = new HashMap<>();
		for (Point2D point : points) {
			updateMap(result, point, null, bandWidth, gridLevel);
		}
		return result.isEmpty() ? null : result;
	}

	/**
	 * Estimate the density in grids
	 * 
	 * @param points
	 *            points points as the input
	 * @param bandWidth
	 *            band width, the effective range of the kernel function
	 * @return the result in a {@link Map}, gridID to density
	 */
	Map<Long, Double> estimate(Point2D[] points, double bandWidth) {
		Map<Long, Double> result = new HashMap<>();
		for (Point2D point : points) {
			updateMap(result, point, null, bandWidth, null);
		}
		return result.isEmpty() ? null : result;
	}

	/**
	 * Update the result map. If there exists an entry, update the density; if not, create one with the density.
	 * @param result the result in a {@link Map}, gridID to density
	 * @param point an input point, density/expectation will be produced with it and filled into grids
	 * @param value the weight of the point. If it is null then it will be treated as 1
	 * @param bandWid the result in a {@link Map}, gridID to density
	 * @param gridLevel  size of grid, {@link GridLevel} 
	 */
	private void updateMap(Map<Long, Double> result, Point2D point, Double value, double bandWidth, GridLevel gridLevel) {
		double weight = (value == null?1:value);
		double baseX = point.getX();
		double baseY = point.getY();
		double x0 = baseX - bandWidth;
		double x1 = baseX + bandWidth;
		double y0 = baseY - bandWidth;
		double y1 = baseY + bandWidth;
		//Generate possible grids
		StringBuffer sb = new StringBuffer();
		sb.append("POLYGON((");
		sb.append(x0);sb.append(' ');sb.append(y0);sb.append(',');
		sb.append(x1);sb.append(" ");sb.append(y0);sb.append(',');
		sb.append(x1);sb.append(" ");sb.append(y1);sb.append(',');
		sb.append(x0);sb.append(" ");sb.append(y1);sb.append(',');
		sb.append(x0);sb.append(" ");sb.append(y0);sb.append("))");
		Geometry polygon = Geometry.CreateFromWkt(sb.toString());
		Set<Long> grids = VirtualGrid.getGridsFromOgrGeometry(polygon, (gridLevel==null?GridLevel.GRID_0_005:gridLevel));
		for (Long grid : grids) {
			Double density = result.get(grid);	
			//bound: x0 x1 y0 y1
			double[] bound = Grid.getBound(grid);
			bound[0]-=baseX;
			bound[1]-=baseX;
			bound[2]-=baseY;
			bound[3]-=baseY;
			double d = K.k(bound[0], bound[1], bound[2], bound[3], bandWidth);
			if(d>0) {//grid with value 0 will be ignored
				d = d*weight;
				if(density == null) {// not in map, create it
					density = d;					
				}else {// in map, add d
					density = density+d;
				}
				//writeback
				result.put(grid, density);
			}			
		}
	}
	
	
	public static void main(String[] args) {
		GridEstimator e = new GridEstimator();
		Point2D[] points = new Point2D[2];
		points[0] = new Point2D.Double(1, 1);
		points[1] = new Point2D.Double(1, 1.3);
		Map<Long,  Double> result = e.estimate(points, 0.2,GridLevel.GRID_0_1);
		for(Long grid: result.keySet()) {
			System.out.println(Grid.getWKT(grid)+"\t"+result.get(grid));
		}
	}
}
