package com.navdata.kernel;

import java.security.InvalidParameterException;
import java.util.Arrays;

import com.navdata.kernel.base.ValueMapper;

/**
 * Reclassify values to 1-100, 0 is reserved for NaN/empty/error.
 * @author Lin DONG
 *
 */
public class Classifier100 extends ValueMapper{

	@Override
	public int[] map(double... values) {
		if(values == null || values.length==0) {
			throw new InvalidParameterException("Array [values] is null or empty.");
		}
		//100 classes
		int N = 100;
		int n = values.length;
		double[] copy =Arrays.copyOf(values, n);
		Arrays.sort(copy);
		double[] seps = new double[N];
		for(int i=0;i<N;i++) {
			int index = (int) (0+i*(1.0*n/N));
			seps[i] = copy[index];
		}
		copy = null;
		int[] result = new int[n];
		for(int i=0;i<n;i++) {
			result[i] = findIndex(values[i], seps);
		}
		return result;
	}
	 
	//0-99 -->1-100
	private int findIndex(double value, double[] seps) {
		int N =seps.length;
		int l = 0;
		int h = N-1;		
		//bin search
		while(h-l>1) {
			int half = (l+h)/2;
			if(value<seps[half]) {	
				h = half;
			}else {
				l = half;
			}
		}		
		return l+1;
	}
	
	public static void main(String[] args) {
		double[] values = new double[10];
		for(int i=0;i<10;i++) {
			values[i] = Math.random()*10;
		}
		
		double[] seps = new double[100];
		for(int i=0;i<100;i++) {
			seps[i] = i*2;
		}
		Classifier100 f = new Classifier100();
		
		int[] index = f.map(values);
		
		for(int i=0;i<10;i++) {
			System.out.println(values[i]+"==>"+index[i]);
		}
	}	
}
