package com.navdata.kernel.base;


/**
 * Map values to index
 * @author Lin DONG
 *
 */
public abstract class ValueMapper {
	
	/**
	 * Map values to index, in other words, give an integer mark to each input value according to some rule
	 * @param values input values
	 * @return marks of the input values
	 */
	abstract public int[] map(double... values);
}
