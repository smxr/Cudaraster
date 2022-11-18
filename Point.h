
#include <string>
#include "utils.h"


class Point{
public:
	double x;
	double y;
	Point(){
		x = 0;
		y = 0;
	}
	Point(double xx, double yy){
		x = xx;
		y = yy;
	}
	void print(){
		printf("POINT (%f %f)\n",x,y);
	}
};
