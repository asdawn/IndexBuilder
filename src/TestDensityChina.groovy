import com.navdata.kernel.GridEstimator
import com.navinfo.grid.Grid
import com.navinfo.grid.GridLevel
import com.navinfo.prj.GISUtil
import com.navinfo.sa.db.DataBase
import java.awt.geom.Point2D

def out = new FileWriter("c:/tmp/canyin.csv")



def conn = DataBase.getConnection("localhost", "5432", "poi", "postgres", "TF-218B")
def statement = conn.createStatement()
def resultset = statement.executeQuery("select dispx,dispy from poi where kind = 110101")

def points = new ArrayList<Point2D>()
int i = 0
while(resultset.next()) {
	i++
	if(i%1000 == 0) {
		println "${i} records load"
	}
	points<< new Point2D.Double(resultset.getDouble(1),resultset.getDouble(2))
}

GridEstimator e = new GridEstimator();
e.HASH_RATIO = 0.5
e.HASH_SIZE = 1000000
Map<Long,  Double> result = e.estimate(points, 0.015,GridLevel.GRID_0_005);
println result.size()+" grids."
result.keySet().each{
	long gridID = it
	double value = result.get(gridID)
	out.write( Grid.getWKT(gridID)+"\t"+value+"\n")
}


