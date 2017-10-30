package com.navdata.kernel.base;

import java.security.InvalidParameterException;

/**
 * 2D Kernel function, here is the integral of the probability density function
 * over a rectangle.
 * 
 * @author Lin DONG
 *
 */
abstract public class Kernel2D {

	/**
	 * Kernel function (probability distribution function)
	 * 
	 * @param x0
	 *            relative min x
	 * @param x1
	 *            relative max x
	 * @param y0
	 *            relative min y
	 * @param y1
	 *            relative max y
	 * @param h
	 *            bandwidth
	 * @return P(x0<x<=x1,y0<y<=y1)
	 */
	abstract public double k(double x0, double x1, double y0, double y1, double h);

	/**
	 * Check parameters, throws {@link InvalidParameterException}.
	 * 
	 * @param x0
	 *            relative min x
	 * @param x1
	 *            relative max x
	 * @param y0
	 *            relative min y
	 * @param y1
	 *            relative max y
	 * @param h
	 *            bandwidth
	 * @return P(x0<x<=x1,y0<y<=y1)
	 */
	protected void checkParameters(double x0, double x1, double y0, double y1, double h)
			throws InvalidParameterException {
		if (x0 > x1 || y0 > y1) {
			throw new InvalidParameterException("x0>x1 or y0>y1.");
		}
		if (h <= 0) {
			throw new InvalidParameterException("Bandwidth(h) should be larger than 0.");
		}
	}
}
