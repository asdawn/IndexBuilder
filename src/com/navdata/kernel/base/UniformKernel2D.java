package com.navdata.kernel.base;

import org.gdal.ogr.Geometry;

/**
 * 2D uniform kernel.
 * @author Lin DONG
 *
 */
public class UniformKernel2D extends Kernel2D{

	/**
	 * The area of a circle (radius = 1)
	 */
	protected final static double AREA = 1*1*Math.PI;
	
	/**
	 * A standard circle, infact it is a polygon
	 */
	protected final static Geometry CIRCLE;
	
	/**
	 * Use an N edges polygon to simulate the circle
	 */
	private final static int N = 100;
	
	/**
	 * SQRT(2)/2, length(side of the inscribed square of CIRCLE) 
	 */
	private final static double A = Math.sqrt(2)/2;
	
	//Build a circle
	static {
		StringBuffer sb = new StringBuffer();
		sb.append("POLYGON((");
		for(int i=0;i<N;i++) {
			double x, y;
			if(i == 0) {
				x = 0;
				y = 1;
			}else {
				double angle = i*(2*Math.PI/N);
				x = Math.sin(angle);
				y = Math.cos(angle);
			}
			sb.append(x);
			sb.append(' ');
			sb.append(y);
			sb.append(',');
		}
		sb.append("0 1))");
		CIRCLE = Geometry.CreateFromWkt(sb.toString());
	}
	
	@Override
	public double k(double x0, double x1, double y0, double y1, double h) {

		//check parameters
		super.checkParameters(x0, x1, y0, y1, h);
		
		//1: no common area
		if(x0>=h || y0>=h || x1<=-h || y1<=-h) {
			return 0;
		}
		//circle is treated as radius=1,  rectangle should be resized to 1/h
		x0/=h;
		x1/=h;
		y0/=h;
		y1/=h;	
		//2: rectangle within circle
		if(x0>=-A && x1<=A && y0>=-A && y1<=A) {
			double rectangleArea = (x1-x0)*(y1-y0);
			double fullArea = AREA;
			double probability = rectangleArea/fullArea;
			return probability;
		}
		
		//3: intersects, but not within

		StringBuffer sb = new StringBuffer();
		sb.append("POLYGON((");
		sb.append(x0);sb.append(' ');sb.append(y0);sb.append(',');
		sb.append(x1);sb.append(" ");sb.append(y0);sb.append(',');
		sb.append(x1);sb.append(" ");sb.append(y1);sb.append(',');
		sb.append(x0);sb.append(" ");sb.append(y1);sb.append(',');
		sb.append(x0);sb.append(" ");sb.append(y0);sb.append("))");
		Geometry polygon = Geometry.CreateFromWkt(sb.toString());
		Geometry intersection = polygon.Intersection(CIRCLE);
		double area = intersection.GetArea();
		double probability = area/AREA;
		return probability;
	}

	

}
