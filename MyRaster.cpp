
#include "MyPolygon.h"




MyRaster::MyRaster(VertexSequence *vst, int sum){
	assert(sum>0);
	vs = vst;							//���ϵĵ������Ǳ��� epp=edge��/pix�� ��num_vertices/epp����pix��
	mbr = vs->getMBR();
    double s=mbr->area();
    step_x=sqrt(s/sum);
    step_y=step_x;
    dimx= int((mbr->high[0]-mbr->low[0])/step_x)-1;
    dimy=int(sum/dimx);                                                          //dimy= int((mbr->high[1]-mbr->low[1])/step_y);
    cout<<"heng:"<<dimx<<"shu:"<<dimy<<endl;
	//double ratio =dimy/dimx;			//����ȵľ���ֵ��y/x

}


MyRaster::~MyRaster(){
	for(vector<Pixel *> &rows:pixels){
		for(Pixel *p:rows){
			delete p;
		}
		rows.clear();
	}
	pixels.clear();
}

void MyRaster::init_pixels(){										//��ʼ�� ����
	assert(mbr);
	double start_x = mbr->low[0];
	double start_y = mbr->low[1];
	for(double i=0;i<=dimx;i++){
		vector<Pixel *> v;
		for(double j=0;j<=dimy;j++){
            Pixel *m = new Pixel();
			m->id[0] = i;
			m->id[1] = j;
			m->low[0] = i*step_x+start_x;
			m->high[0] = (i+1.0)*step_x+start_x;
			m->low[1] = j*step_y+start_y;
			m->high[1] = (j+1.0)*step_y+start_y;

            m->centralpoint.x=(m->low[0]+m->high[0])/2;
            m->centralpoint.y=(m->low[1]+m->high[1])/2;
            //m->centralpoint.print();
			candidates.push(m->centralpoint);
			v.push_back(m);
		}
		pixels.push_back(v);
	};
	
}
