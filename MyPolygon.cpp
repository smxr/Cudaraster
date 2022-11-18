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
	p = new Point[nv];          //����
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
//bool VertexSequence::contain(Point po){            //���ﲻ���޸� ������ַ ��
//    bool con=false;          //���һ�ζ�û���ཻ�Ļ�������������
//    //assert(nv>=3);            //���� �����Ͼ��㽻
//    //cout<<"��o";
//    //po.print();
//    int i=0,j=num_vertices-1;
//    for(i;i<num_vertices;i++){
//        if(po.x==p[i].x&&po.y==p[i].y){
//            //cout<<"�ڱ߽��"<<endl;
//            return true;
//        }
//        if((po.y>=p[i].y)!=(po.y>=p[j].y)){                                      //��*<0 �����������
//            int linex=p[i].x+(po.y-p[i].y)*(p[i].x-p[j].x)/(p[i].y-p[j].y);
//            if(linex==po.x){
//                //cout<<"�ڱ���"<<endl;
//                return true;            //�ڱ���ֱ����contain
//            }
//            if(linex>po.x){
//                con=!con;
//                //cout<<"�ཻ�ڵ�"<<j<<"���"<<i<<endl;
//                //p[j].print();
//                //p[i].print();
//                //cout<<endl;
//            }
//        }
//        j=i;
//    }
//    return con;
//}

bool VertexSequence::contain(Point po) {					//�øĹ���contain�ɣ��߽��������࣬ԭ����Ҳ������
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


