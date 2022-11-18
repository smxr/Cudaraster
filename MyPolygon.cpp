#include <string.h>
#include <assert.h>
#include <iostream>
#include <fstream>
#include <float.h>
#include <sstream>
#include <vector>
#include <thread>
#include <unordered_map>

#include "MyPolygon.h"

using namespace std;

VertexSequence::VertexSequence(int nv){
	p = new Point[nv];
	num_vertices = nv;
}
VertexSequence::VertexSequence(int nv, Point *pp){
	assert(nv>0);
	num_vertices = nv;
	p = new Point[nv];          //数组
	memcpy((char *)p,(char *)pp,num_vertices*sizeof(Point));
};

void VertexSequence::print(bool complete_ring){
	cout<<"(";
	for(int i=0;i<num_vertices;i++){
		if(i!=0){
			cout<<",";
		}
		printf("%f ",p[i].x);
		printf("%f",p[i].y);
	}
	// the last vertex should be the same as the first one for a complete ring
	if(complete_ring){
		if(p[0].x!=p[num_vertices-1].x||p[0].y!=p[num_vertices-1].y){
			cout<<",";
			printf("%f ",p[0].x);
			printf("%f",p[0].y);
		}
	}
	cout<<")";
}

//==================================================================//
//bool VertexSequence::contain(Point po){            //这里不用修改 不传地址 吧
//    bool con=false;          //如果一次都没有相交的话，就是在外面
//    //assert(nv>=3);            //不用 在线上就算交
//    //cout<<"点o";
//    //po.print();
//    int i=0,j=num_vertices-1;
//    for(i;i<num_vertices;i++){
//        if(po.x==p[i].x&&po.y==p[i].y){
//            //cout<<"在边界点"<<endl;
//            return true;
//        }
//        if((po.y>=p[i].y)!=(po.y>=p[j].y)){                                      //用*<0 会增大计算量
//            int linex=p[i].x+(po.y-p[i].y)*(p[i].x-p[j].x)/(p[i].y-p[j].y);
//            if(linex==po.x){
//                //cout<<"在边上"<<endl;
//                return true;            //在边上直接算contain
//            }
//            if(linex>po.x){
//                con=!con;
//                //cout<<"相交于点"<<j<<"与点"<<i<<endl;
//                //p[j].print();
//                //p[i].print();
//                //cout<<endl;
//            }
//        }
//        j=i;
//    }
//    return con;
//}

bool VertexSequence::contain(Point po) {					//用改过的contain吧，边界就这样差不多，原来的也不完美
    bool con = false;       
    int i = 0, j = num_vertices - 1;
    for (i; i < num_vertices; i++) {
        if ((po.y >= p[i].y) != (po.y >= p[j].y)) {                                      
            int linex = p[i].x + (po.y - p[i].y) * (p[i].x - p[j].x) / (p[i].y - p[j].y);
            if (linex > po.x) {
                con = !con;
            }
        }
        j = i;
    }
    return con;
}

box *VertexSequence::getMBR(){
	double min_x =180, min_y = 90, max_x = -180, max_y = -90;
	for(int i=0;i<num_vertices;i++){
		if(min_x>p[i].x){
			min_x = p[i].x;
		}
		if(max_x<p[i].x){
			max_x = p[i].x;
		}
		if(min_y>p[i].y){
			min_y = p[i].y;
		}
		if(max_y<p[i].y){
			max_y = p[i].y;
		}
	}
	box *mbr = new box();
	mbr->low[0] = min_x;
	mbr->low[1] = min_y;
	mbr->high[0] = max_x;
	mbr->high[1] = max_y;
	return mbr;
}


