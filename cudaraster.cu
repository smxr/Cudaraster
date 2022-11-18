//#include <bits/stdc++.h>
#include <iostream>
#include <fstream>
#include <cassert>
#include <string>
#include <sstream>
#include <vector>

#include "MyPolygon.h"


using namespace std;

#define BLOCK_SIZE 1024

__global__ void gpu_internalpoints(Point* po, Point* p, int num_vertices, bool* ips)         //(d_waits,d_Polypoints,Polycount,d_ips)
{
    int Pointindex = blockIdx.x * blockDim.x + threadIdx.x; 
    ips[Pointindex]=false;       
    int i = 0, j = num_vertices - 1;
    for (i; i < num_vertices; i++) {
        if ((po[Pointindex].y >= p[i].y) != (po[Pointindex].y >= p[j].y)) {                                      
            int linex = p[i].x + (po[Pointindex].y - p[i].y) * (p[i].x - p[j].x) / (p[i].y - p[j].y);
            if (linex > po[Pointindex].x) {
                ips[Pointindex] = !ips[Pointindex];
            }
        }
        j = i;
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

    int num_pixel=1000000;
    MyRaster raster(&polygon,num_pixel);
    raster.init_pixels();

    int waitscount=raster.candidates.size();
    int Polycount=polygon.num_vertices;
    Point *waits, *Polypoints;
    bool *containIndex;
    cudaMallocHost((void**)&waits, sizeof(Point) * waitscount);
    cudaMallocHost((void**)&Polypoints, sizeof(Point) * Polycount);
    cudaMallocHost((void**)&containIndex, sizeof(bool) * waitscount);
    for(int i=0;i<waitscount;i++){
    	waits[i]=raster.candidates.front();
    	raster.candidates.pop();
    }
    
    Polypoints=polygon.p;
    
    Point *d_waits, *d_Polypoints;
    bool *d_ips;
    cudaMalloc((void**)&d_waits, sizeof(Point) * waitscount);
    cudaMalloc((void**)&d_Polypoints, sizeof(Point) * Polycount);
    cudaMalloc((void**)&d_ips, sizeof(bool) * waitscount);
    
    cudaMemcpy(d_waits, waits, sizeof(Point) * waitscount, cudaMemcpyHostToDevice);
    cudaMemcpy(d_Polypoints, Polypoints, sizeof(Point) * Polycount, cudaMemcpyHostToDevice);

    unsigned int gridlength = (waitscount + BLOCK_SIZE - 1) / BLOCK_SIZE;
    gpu_internalpoints << <gridlength, BLOCK_SIZE >> > (d_waits,d_Polypoints, Polycount,d_ips);
    cudaMemcpy(containIndex, d_ips, sizeof(bool) *waitscount, cudaMemcpyDeviceToHost);
    vector<Point> ips;
    for(int i=0;i<waitscount;i++){
        if(containIndex[i]==true)
        ips.push_back(waits[i]);
    }
    
    //for(int i=0;i<ips.size();i++){
    //    ips[i].print();
    //}

    writewkt(ips);

    return 0;



}



