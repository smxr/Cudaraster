//#include <bits/stdc++.h>
#include <iostream>
#include <fstream>
#include <cassert>
#include <string>
#include <sstream>
#include <vector>

#include "MyPolygon.h"


using namespace std;

#define BLOCK_SIZE 16

//传二维没必要 传bool也没必要

__global__ void gpu_internalpoints(double start_x,double start_y,double step, int dimx, Point* p, int num_vertices, bool* ips)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

	double low[2],high[2];
	low[0] = row*step+start_x;
	high[0] = (row+1.0)*step+start_x;
	low[1] = col*step+start_y;
	high[1] = (col+1.0)*step+start_y;

	double x=(low[0]+high[0])/2;
	double y=(low[1]+high[1])/2;
	//temp.print();


	int Pointindex= row*blockDim.x+col;				//row*liekuan +col
	ips[Pointindex]=false;
	int i = 0, j = num_vertices - 1;
	for (i; i < num_vertices; i++) {
		if ((y >= p[i].y) != (y >= p[j].y)) {
			int linex = p[i].x + (y - p[i].y) * (p[i].x - p[j].x) / (p[i].y - p[j].y);
			if (linex > x) {
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

    int num_pixel=200000;
    MyRaster raster(&polygon,num_pixel);
    //raster.init_pixels();

    double start_x, start_y, step;
    start_x=raster.get_start_x();
    start_y=raster.get_start_y();
    step=raster.get_step_x();

    int waitscount=num_pixel;			//raster.candidates.size()
    int Polycount=polygon.num_vertices;
    Point *Polypoints;
    bool *containIndex;
    //cudaMallocHost((void**)&waits, sizeof(Point) * waitscount);
    cudaMallocHost((void**)&Polypoints, sizeof(Point) * Polycount);
    cudaMallocHost((void**)&containIndex, sizeof(bool) * waitscount);
//    for(int i=0;i<waitscount;i++){
//    	waits[i]=raster.candidates.front();
//    	raster.candidates.pop();
//    }
    
    Polypoints=polygon.p;
    Point *d_Polypoints;
    bool *d_ips;
    //cudaMalloc((void**)&d_waits, sizeof(Point) * waitscount);
    cudaMalloc((void**)&d_Polypoints, sizeof(Point) * Polycount);
    cudaMalloc((void**)&d_ips, sizeof(bool) * waitscount);
    
    //cudaMemcpy(d_waits, waits, sizeof(Point) * waitscount, cudaMemcpyHostToDevice);
    cudaMemcpy(d_Polypoints, Polypoints, sizeof(Point) * Polycount, cudaMemcpyHostToDevice);
    int dimx=raster.get_dimx();
    int dimy=raster.get_dimy();
	unsigned int grid_rows = (dimx + BLOCK_SIZE - 1) / BLOCK_SIZE;
	unsigned int grid_cols = (dimy + BLOCK_SIZE - 1) / BLOCK_SIZE;
	dim3 dimGrid(grid_cols, grid_rows);
	dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);
	cout<<"before Entry gpu"<<endl;
    gpu_internalpoints << <dimGrid, dimBlock >> > (start_x, start_y, step, dimx, d_Polypoints, Polycount,d_ips);
    cout<<"After gpu"<<endl;
    cudaMemcpy(containIndex, d_ips, sizeof(bool) *waitscount, cudaMemcpyDeviceToHost);
    cudaThreadSynchronize();
    vector<Point> ips;
    
    for(double i=0;i<=dimx;i++){
		for(double j=0;j<=dimy;j++){
			int Pointindex= i*dimx+j;
			if(containIndex[Pointindex]==true){
				Pixel *m = new Pixel();

				m->id[0] = i;
				m->id[1] = j;
				m->low[0] = i*step+start_x;
				m->high[0] = (i+1.0)*step+start_x;
				m->low[1] = j*step+start_y;
				m->high[1] = (j+1.0)*step+start_y;

				m->centralpoint.x=(m->low[0]+m->high[0])/2;
				m->centralpoint.y=(m->low[1]+m->high[1])/2;
				//m->centralpoint.print();
				ips.push_back(m->centralpoint);
			}
		}
	};

    //for(int i=0;i<ips.size();i++){
    //    ips[i].print();
    //}

    writewkt(ips);

    return 0;



}



