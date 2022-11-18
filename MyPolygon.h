#include <vector>
//#include <string>
#include <stdint.h>
#include <math.h>
#include <stack>
#include <map>
#include <bits/stdc++.h>

//#include "Point.h"
#include "Pixel.h"

using namespace std;

class VertexSequence{
public:
	int num_vertices = 0;
	Point *p = NULL;
public:
    //VertexSequence(){};
	VertexSequence(int nv);
	VertexSequence(int nv, Point *pp);
    bool contain(Point po);
    void print(bool complete_ring=false);
    box *getMBR();

};


class MyRaster{
	box *mbr = NULL;
	VertexSequence *vs = NULL;
	vector<vector<Pixel *>> pixels;
	double step_x = 0.0;
	double step_y = 0.0;
	int dimx = 0;
	int dimy = 0;
	//void init_pixels();
	void evaluate_edges();
	void scanline_reandering();

public:

	MyRaster(VertexSequence *vs, int sum);
	queue<Point> candidates;

	void rasterization();
	~MyRaster();
    void init_pixels();

	bool contain(box *,bool &contained);
	vector<Pixel *> get_intersect_pixels(box *pix);
	vector<Pixel *> get_closest_pixels(box *target);
	Pixel *get_pixel(Point &p);
	Pixel *get_closest_pixel(Point &p);
	Pixel *get_closest_pixel(box *target);
	vector<Pixel *> expand_radius(int lowx, int highx, int lowy, int highy, int step);
	vector<Pixel *> expand_radius(Pixel *center, int step);

	int get_offset_x(double x);
	int get_offset_y(double y);

	/* statistics collection*/
	int count_intersection_nodes(Point &p);
	int get_num_border_edge();
	size_t get_num_pixels();
	size_t get_num_pixels(PartitionStatus status);
	size_t get_num_gridlines();
	size_t get_num_crosses();
	void print();

	vector<Pixel *> get_pixels(PartitionStatus status);
	box *extractMER(Pixel *starter);

	vector<Pixel *> retrieve_pixels(box *);

	/*
	 * the gets functions
	 *
	 * */
	double get_step_x(){
		return step_x;
	}
	double get_step_y(){
		return step_y;
	}

	int get_dimx(){
		return dimx;
	}
	int get_dimy(){
		return dimy;
	}
	int get_start_x(){
		return mbr->low[0];					//new
	}
	int get_start_y(){
		return mbr->low[1];
	}


	Pixel *get(int dx, int dy){				//��������pix	ȷʵ�Ǵ�0��ʼ�İ�
		assert(dx>=0&&dx<=dimx);
		assert(dy>=0&&dy<=dimy);
		return pixels[dx][dy];
	}

};
