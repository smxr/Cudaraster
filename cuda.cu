#include <stdlib.h>
#include <math.h>
#include <iostream>
#include <fstream>
#include <cassert>
#include <string>
//#include <sstream>     
#include <vector>
#include <time.h>


using namespace std;

#define BLOCK_SIZE 16



__global__ void gpu_matrix_mult(int* a, int* b, int* c, int m, int n, int k)
{
    int row = blockIdx.y * blockDim.y + threadIdx.y;                //在前面反着定义的，现在再反一次就能正着用了     
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    //blockIdx.x为dimGrid的第一个参数，也就是grid_cols范围内的一个值，  blockIdx.y为grid_rows内     
    //blockDim.y blockDim.x就是block在相应方向的长宽，都是16 表示这个方向长16个线程
    //threadIdx 线程索引 更好理解了，就是0到15中一个数

    int sum = 0;
    if (col < k && row < m)
    {
        for (int i = 0; i < n; i++)
        {
            sum += a[row * n + i] * b[i * k + col];
        }
        c[row * k + col] = sum;
    }
}

void cpu_matrix_mult(int* h_a, int* h_b, int* h_result, int m, int n, int k) {
    for (int i = 0; i < m; ++i)
    {
        for (int j = 0; j < k; ++j)
        {
            int tmp = 0.0;
            for (int h = 0; h < n; ++h)
            {
                tmp += h_a[i * n + h] * h_b[h * k + j];
            }
            h_result[i * k + j] = tmp;
        }
    }
}

void writetxt(int* a, int row, int column, string txtname) {
    ofstream out(txtname + ".txt");
    if (out.is_open()) {

        for (int i = 0; i < row; ++i) {
            for (int j = 0; j < column; ++j) {
                out << a[i * row + j] << " ";
            }
            out << endl;
        }
        out.close();
    }
}

int main(int argc, char const* argv[])
{
    int m = 2000;
    int n = 2000;
    int k = 2000;

    int* h_a, * h_b, * h_c, * h_cc;
    cudaMallocHost((void**)&h_a, sizeof(int) * m * n);              
    cudaMallocHost((void**)&h_b, sizeof(int) * n * k);
    cudaMallocHost((void**)&h_c, sizeof(int) * m * k);
    cudaMallocHost((void**)&h_cc, sizeof(int) * m * k);
    //cudaMallocHost((void**)&h_ccc, sizeof(int) * m * k);

    for (int i = 0; i < m; ++i) {
        for (int j = 0; j < n; ++j) {
            h_a[i * n + j] = rand() % 1024;
        }
    }

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < k; ++j) {
            h_b[i * k + j] = rand() % 1024;
        }
    }
    writetxt(h_a, m, n, "h_a");
    writetxt(h_b, n, k, "h_b");

    clock_t start1, stop1, start2, stop2;
    start1 = clock();

    int* d_a, * d_b, * d_c;
    cudaMalloc((void**)&d_a, sizeof(int) * m * n);
    cudaMalloc((void**)&d_b, sizeof(int) * n * k);
    cudaMalloc((void**)&d_c, sizeof(int) * m * k);

    // copy matrix A and B from host to device memory
    cudaMemcpy(d_a, h_a, sizeof(int) * m * n, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, h_b, sizeof(int) * n * k, cudaMemcpyHostToDevice);

    unsigned int grid_rows = (m + BLOCK_SIZE - 1) / BLOCK_SIZE;                 //采用二维grid 相当于m+1除以16向下取整
    unsigned int grid_cols = (k + BLOCK_SIZE - 1) / BLOCK_SIZE;
    dim3 dimGrid(grid_cols, grid_rows);                                         //讲过了就是这么反着排的，表示了一个grid的x y方向的大小    //dim3是3维的意思，这里第三参数默认为1，用的是二维
    dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE);

    gpu_matrix_mult << <dimGrid, dimBlock >> > (d_a, d_b, d_c, m, n, k);     //gpu_matrix_mult运行一次是一个线程处理矩阵中的一个空，这里运行 dimGrid*diBlock=grid_cols*grid_rows*BLOCK_SIZE*BLOCK_SIZE略>=m*k次

    cudaMemcpy(h_c, d_c, sizeof(int) * m * k, cudaMemcpyDeviceToHost);
    //cudaThreadSynchronize();

    stop1 = clock();

    start2 = clock();
    cpu_matrix_mult(h_a, h_b, h_cc, m, n, k);
    stop2 = clock();

    

    double endtime1 = (double)(stop1 - start1) / CLOCKS_PER_SEC;
    std::cout << "cudatime: " << endtime1 << "s" << std::endl;
    double endtime2 = (double)(stop2 - start2) / CLOCKS_PER_SEC;
    std::cout << "cputime: " << endtime2 << "s" << std::endl;



    int ok = 1;
    for (int i = 0; i < m; ++i)
    {
        for (int j = 0; j < k; ++j)
        {
            if (fabs(h_cc[i * k + j] - h_c[i * k + j]) > (1.0e-10))
            {

                ok = 0;
            }
        }
    }



    if (ok )
    {
        printf("Pass!!!\n");
    }
    else
    {
        printf("Error!!!\n");
    }

    writetxt(h_c, m, k, "h_c");
    writetxt(h_cc, m, k, "h_cc");


    // free memory
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);
    cudaFreeHost(h_a);
    cudaFreeHost(h_b);
    cudaFreeHost(h_c);
    cudaFreeHost(h_cc);
    return 0;
}
