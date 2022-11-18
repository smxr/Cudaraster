//#include <bits/stdc++.h>
//#include <iostream>
#include <fstream>
#include <cassert>
#include <string>
#include <sstream>
#include <vector>

#include "MyPolygon.h"


using namespace std;

#define BLOCK_SIZE 1024

__global__ void gpu_internalpoints(Point* po, int num_pix, Point* p, int num_vertices)         //(d_waits,d_Polypoints,Polycount,d_ips)
{
    int Pointindex = blockIdx.x * blockDim.x + threadIdx.x;
    if(Pointindex<num_pix){
    	assert(po[Pointindex].x!=0&&po[Pointindex].y!=0);
    	bool temp=false;			//false=out    true=in
 		int i = 0, j = num_vertices - 1;
		for (i; i < num_vertices; i++) {
			if ((po[Pointindex].y >= p[i].y) != (po[Pointindex].y >= p[j].y)) {
				int linex = p[i].x + (po[Pointindex].y - p[i].y) * (p[i].x - p[j].x) / (p[i].y - p[j].y);
				if (linex > po[Pointindex].x) {
					temp=!temp;
				}
			}
			j = i;
		}
		if(temp==false){
			po[Pointindex].x=0;
			po[Pointindex].y=0;
		}
    }
}

string readhang(string file){
    string hang;
    ifstream infile;
    infile.open(file.data());
    assert(infile.is_open());

    getline(infile,hang);
    getline(infile,hang);
    //cout<<wkt;
    infile.close();
    return hang;
}

void stringsplit(string str,const char split,vector<string>& raw){
	istringstream iss(str);
	string token;
	while (getline(iss, token, split))
	{
		raw.push_back(token);
	}
}

void rawpointsplit(vector<string>& raw,const char split,Point *coordinate){
	string token;
	stringstream stream;
	double n;
	for(int i=0;i<raw.size();i++){
        istringstream iss(raw[i]);
        getline(iss, token, split);
        stream<<token;
        assert(n>=0);
        stream>>n;
        coordinate[i].x=n;
        stream.clear();

        getline(iss, token, split);
        stream<<token;
        stream>>n;
        assert(n>=0);
        coordinate[i].y=n;
        //coordinate[i].print();
        stream.clear();
	}

}

vector<Point > internalpoints(VertexSequence polygon,MyRaster raster){
    int dimx=raster.get_dimx();
    int dimy=raster.get_dimy();
    vector<Point > ip;
	for(double i=0;i<=dimx;i++){
		for(double j=0;j<=dimy;j++){
            Pixel *checkpix=raster.get(i,j);
            if(polygon.contain(checkpix->centralpoint)){
                ip.push_back(checkpix->centralpoint);
            }

		}
	};
	return ip;
}

void writewkt(vector<Point> ips){
    ofstream out("ips.wkt");
    if (out.is_open()){
        out << "MultiPoint(";
        for(int i=0;i<ips.size();i++){
            if(i>=1) out<<",";
            out<<"("<<ips[i].x<<" "<<ips[i].y<<")";
        }
        out<<")";
        out.close();
    }
}

int main(){
    string filename="bigpolygon.wkt";
    string wkt=readhang(filename);
    vector<string> rawpoints;

	stringsplit(wkt,',',rawpoints);
    rawpoints[0]=rawpoints[0].substr(9,rawpoints[0].length());                      //POLYGON((129.536643 49.398036
    int last=rawpoints.size()-1;
    rawpoints[last]=rawpoints[last].substr(0,rawpoints[last].length()-2);           //129.520371 49.413440))

    Point *pp=new Point[rawpoints.size()];
    rawpointsplit(rawpoints,' ',pp);
    VertexSequence polygon(rawpoints.size(),pp);
    cout<<polygon.num_vertices<<endl;
    Point position(92.6, 43.7);
    if(polygon.contain(position)){
        cout<<"surely contain";
    }
    else cout<<"out";
    cout<<endl;
    box *MBR=polygon.getMBR();
    MBR->print();
    cout<<endl;
    double s=MBR->area();
    cout<<s<<endl;

    int num_pixel=20000;
    MyRaster raster(&polygon,num_pixel);
    raster.init_pixels();

    int waitscount=raster.candidates.size();
    int Polycount=polygon.num_vertices;
    Point *waits, *Polypoints;
    cudaMallocHost((void**)&waits, sizeof(Point) * waitscount);
    cudaMallocHost((void**)&Polypoints, sizeof(Point) * Polycount);
    for(int i=0;i<waitscount;i++){
    	waits[i]=raster.candidates.front();
    	raster.candidates.pop();
    }

    Polypoints=polygon.p;
    Point *d_waits, *d_Polypoints;
    cudaMalloc((void**)&d_waits, sizeof(Point) * waitscount);
    cudaMalloc((void**)&d_Polypoints, sizeof(Point) * Polycount);

    cudaMemcpy(d_waits, waits, sizeof(Point) * waitscount, cudaMemcpyHostToDevice);
    cudaMemcpy(d_Polypoints, Polypoints, sizeof(Point) * Polycount, cudaMemcpyHostToDevice);

    unsigned int gridlength = (waitscount + BLOCK_SIZE - 1) / BLOCK_SIZE;
    SpendTime *time=new SpendTime();
    gpu_internalpoints << <gridlength, BLOCK_SIZE >> > (d_waits, waitscount, d_Polypoints, Polycount);
    cudaDeviceSynchronize();
    cout<<"Gpu:";
    delete time;
    cudaMemcpy(waits, d_waits, sizeof(Point) * waitscount, cudaMemcpyDeviceToHost);
    vector<Point> ips;
    for(int i=0;i<waitscount;i++){
        if(waits[i].x==0&&waits[i].y==0);
        else ips.push_back(waits[i]);
    }


    MyRaster raster0(&polygon,num_pixel);
	raster0.init_pixels();
	SpendTime *time0=new SpendTime();
	vector<Point> ips0=internalpoints(polygon,raster0);
	cout<<"Cpu:";
	delete time0;
	cout<<"ips.size"<<ips.size()<<endl;
	cout<<"ips0.size"<<ips0.size()<<endl;
	if(ips.size()==ips0.size()){
		cout<<"size right"<<endl;
		for(int i=0;i<ips.size();i++){
			if(ips[i].x!=ips0[i].x){
				cout<<i<<"diffderence"<<endl;
				break;
			}
			if(ips[i].y!=ips0[i].y){
				cout<<i<<"diffderence"<<endl;
				break;
			}
		}
	}

    writewkt(ips);

    return 0;

}
//nvcc cudaraster4.cu MyPolygon.cpp MyRaster.cpp Pixel.cpp -o main4







