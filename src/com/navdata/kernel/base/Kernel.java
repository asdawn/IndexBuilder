package com.navdata.kernel.base;

import java.security.InvalidParameterException;

/**
 * Kernel function, here is the integral of the probability density function
 * over a range.
 * 
 * @author Lin DONG
 *
 */
public abstract class Kernel {

	/**
	 * Kernel function (probability distribution function)
	 * 
	 * @param x0
	 *            relative start position of the range
	 * @param x1
	 *            relative end position of the range
	 * @param h
	 *            bandwidth
	 * @return P(x0<x<=x1)
	 */
	abstract public double k(double x0, double x1, double h);

	/**
	 * Check parameters, throws {@link InvalidParameterException}
	 * 
	 * @param x0
	 *            relative start position of the range
	 * @param x1
	 *            relative end position of the range
	 * @param h
	 *            bandwidth
	 */
	protected void checkParameters(double x0, double x1, double h) throws InvalidParameterException {
		// check parameters
		if (x0 > x1) {
			throw new InvalidParameterException("x0>x1");
		}
		if (h <= 0) {
			throw new InvalidParameterException("Bandwidth(h) should be larger than 0.");
		}
	}
}
