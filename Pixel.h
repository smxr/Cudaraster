#include "Point.h"
#include <float.h>

#define BOX_GLOBAL_MIN 100000.0
#define BOX_GLOBAL_MAX -100000.0

class box{
public:
	double low[2] = {BOX_GLOBAL_MIN,BOX_GLOBAL_MIN};
	double high[2] = {BOX_GLOBAL_MAX,BOX_GLOBAL_MAX};

	box(){}						//这是叫个？

	box(box *b){
		low[0] = b->low[0];
		high[0] = b->high[0];
		low[1] = b->low[1];
		high[1] = b->high[1];
	}
	box (double lowx, double lowy, double highx, double highy){
		low[0] = lowx;
		low[1] = lowy;
		high[0] = highx;
		high[1] = highy;
	}
	bool valid();



	double area();
	bool intersect(Point &start, Point &end);
	bool intersect(box &target);
	bool contain(box &target);
	bool contain(Point &p);

	// distance to box
	double distance(box &target, bool geography);
	double max_distance(box &target, bool geography);

	// distance to point
	double distance(Point &p, bool geography);
	double max_distance(Point &p, bool geography);

	// distance to segment
	double distance(Point &start, Point &end, bool geography);
	double max_distance(Point &start, Point &end, bool geography);

	box expand(double expand_buffer, bool geography);

	void print_vertices();
	void print();
	void to_array(Point *p);
};

enum PartitionStatus{			//enum 枚举类型
	OUT = 0,
	BORDER = 1,
	IN = 2
};

class Pixel:public box{
	//vector<cross_info> crosses;

public:
	unsigned short id[2];
	PartitionStatus status = OUT;
    Point centralpoint;                             //把这个点写在这里

public:
	bool is_boundary(){
		return status == BORDER;
	}
	bool is_internal(){
		return status == IN;
	}
	bool is_external(){
		return status == OUT;
	}
	bool pixel_valid();

};

inline bool comparePixelX(box *p1, box *p2)
{
    return (p1->low[0] < p2->low[0]);
}

inline bool comparePixelY(box *p1, box *p2)
{
    return (p1->low[1] < p2->low[1]);
}

inline bool compareHighPixelX(box *p1, box *p2)
{
    return (p1->low[0] < p2->low[0]);
}

inline bool compareHighPixelY(box *p1, box *p2)
{
    return (p1->low[1] < p2->low[1]);
}
