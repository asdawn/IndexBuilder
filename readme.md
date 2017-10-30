# Index Builder

### Main Aim
Given OSM (Open Street Map) like data, how to answer questions such as
+ which part of the city is more convenient to live?
+ where to have a meal or buy clothes?
+ which district is likely to be suffering inadequate medicare ?
+ where to open a new hotel?

A good way is to analyze the whole city with a map. The map should show the distribution of all kinds of resources of the city, using grids or contours.

There are hundred of kinds of POIs, to make such set of maps for ONE city by hand is awesomely boring. How could we deal with a whole country or continent?

So I write something to do this work automatically. Including:

+ Calculate the density of POIs (kind by kind, city by city)
+ Map density to a 0-100 index
+ Build grids and evaluate the index of each grid
+ Make contours
+ Publish the result as WFS service

### Plan

I have to deal with the first part. Then most work can be done with PostGIS, just using build-in tools and several SQLs. The detailed plan is:

1. Kernel density estimation

  Here we use the **kernel** method (https://en.wikipedia.org/wiki/Kernel_density_estimation). It is fast, and *easy to understand (of course easy to implement)*. To make things easy, I'll ignore *ALL* the mathematical details (that means you have to choose the kernel and bandwidth by yourself), and just implement 1 to 3 kernels：

  + Uniform
  + Triangular
  + Gaussian

  The formulas and graphs(2D) can be find in
   <https://en.wikipedia.org/wiki/Kernel_(statistics)>.

  Maybe a real-time service is needed, so I choose the fastest kernel (uniform) as the first choice. Triangular is also very fast, and it seems this kernel is better according to the table given in the wikipedia page. Gaussian is for mathematicians, they like it, but I do not.
  >Yes, Gasussian is great. However here the output is a raster layer (regular grids with values). If we use Gasussian, we have to calculate the **integral** of density in each grid. Forgive me, I'm not good on this. Maybe my girl friend can give me the formula - she's a math genius.

2. Map density to index
  The density varies greatly betweens density rasters. The result can be more readable by mapping density to a index value between 0 and 100. 0 means there's no such pois nearby, 1 means a little, 100 means plenty of. 

3. Extract contours

  Read the reclassified raster, then extract contours.
  For batch works, I prefer PostGIS or GDAL. There should be a lot of codes on Github so make up a real-time interface is possible. After this, there are extra works:

  + Convert rings to polygons, and make holes to avoid overlaps - then it can be placed on web with *color ramp* (a set of gradient colors).
  + Save the result to database and publish them; or write a WFS-like service.
  
  
### requires

GDAL (gdal-bin, gdal-java)  
