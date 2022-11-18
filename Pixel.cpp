#include "Pixel.h"

double box::area(){
    return (high[0]-low[0])*(high[1]-low[1]);
}

void box::print_vertices(){
	printf("%f %f, %f %f, %f %f, %f %f, %f %f",
				low[0],low[1],
				high[0],low[1],
				high[0],high[1],
				low[0],high[1],
				low[0],low[1]);
}

void box::print(){
	printf("POLYGON((");
	print_vertices();
	printf("))\n");

}

bool box::valid(){
	return low[0] <= high[0] && low[1] <= high[1];

}

bool Pixel::pixel_valid(){
	return (high[0]-low[0])==(high[1]-low[1]);

}
