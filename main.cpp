//#include <bits/stdc++.h>
#include <iostream>
#include <fstream>
#include <cassert>
#include <string>
#include <sstream>
#include <vector>

//#include "point.h"
#include "MyPolygon.h"

//only cpu

using namespace std;

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
    ofstream out("ips0.wkt");
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
        cout<<"contain";
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
    //int nump=(raster.dimx+1)*(raster.dimy+1)
    //Point *ip=new Point[nump];
    vector<Point> ips=internalpoints(polygon,raster);
    //for(int i=0;i<ips.size();i++){
    //    ips[i].print();
    //}

    writewkt(ips);

    return 0;



}


