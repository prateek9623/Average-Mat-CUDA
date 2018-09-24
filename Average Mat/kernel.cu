#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cuda.h>
#include <device_functions.h>
#include <cuda_runtime_api.h>
#include "time.h";
#include <curand.h>
#include <curand_kernel.h>
#include <iostream>

#define RADIUS 1
#define MATRIX_SIZE 50
#define MAX 10

using namespace std;

 void fillRandom(int *matrix, int maxX, int maxY, int range, unsigned long seed) 
{
	 srand(seed);
	 for (int i = 0; i < maxX; i++)
		 for (int j = 0; j < maxY; j++)
			 *((matrix+i*maxY)+j) = rand() % MAX;
}

__global__ void findAverage(int *matrix, int *avgMatrix, int maxX, int maxY, int radius, int count, int sharedBlockSize) {
	int x = threadIdx.x + blockIdx.x*blockDim.x;
	int y = threadIdx.y + blockIdx.y*blockDim.y;
	int index = x + maxX * y;

	extern __shared__ int sharedData[];

	//int blockIndex = x + blockDim.x *y;
	//int blockSize = blockDim.x*blockDim.y;
	//int blockClipSize = sharedBlockSize / blockSize + 1;
	//int blockClipStart = blockClipSize * blockIndex;
	//if (blockClipStart < blockSize) {
	//	for (int i = 0; i < blockClipSize; i++) {
	//	}
	//}

	printf("\n%d %d", x, y);
}
//__global__ void findAverage(int *matrix, int *avgMatrix, int maxX, int maxY, int radius, int count) {
//	int x = threadIdx.x + blockIdx.x*blockDim.x;
//	int y = threadIdx.y + blockIdx.y*blockDim.y;
//	int index = x + maxX*y;
//	
//	if (x < maxX && y < maxY) {
//		int sum = 0;
//		int cou = 0;
//		for (int offsetY = y - radius; offsetY <= y + radius && offsetY < maxY; offsetY++) {
//			for (int offsetX = x - radius; offsetX <= x + radius && offsetX < maxX; offsetX++) {
//				if (offsetX >= 0 && offsetY >= 0)
//				{
//					int indexOffset = offsetY * maxX + offsetX;
//					sum += matrix[indexOffset];
//				}
//			}
//		}
//		avgMatrix[index] = sum / count;
//		//__syncthreads();
//		//printf("%d ", avgMatrix[index]);
//	}
//}


int main()
{
	int matrix[MATRIX_SIZE][MATRIX_SIZE];
	int avgMatrix[MATRIX_SIZE][MATRIX_SIZE];

	int *dMatrix;
	int *dAvgMatrix;

	cudaFree(0);

	fillRandom((int*)matrix, MATRIX_SIZE, MATRIX_SIZE, 10, time(NULL));
	int totalElements = MATRIX_SIZE * MATRIX_SIZE;

	if (cudaMalloc(&dMatrix, sizeof(int)*totalElements) != cudaSuccess) {
		cerr << "Couldn't allocate memory for matrix";
		cudaFree(dMatrix);
	};

	if (cudaMalloc(&dAvgMatrix, sizeof(int)*totalElements) != cudaSuccess) {
		cerr << "Couldn't allocate memory for Average Matrix";
		cudaFree(dAvgMatrix);
	};

	if (cudaMemcpy(dMatrix, matrix, sizeof(int)*totalElements, cudaMemcpyHostToDevice) != cudaSuccess) {
		cerr << "Couldn,t initialiZe device Original Matrix";
		cudaFree(dMatrix);
		cudaFree(dAvgMatrix);
	}

	if (cudaMemset(dAvgMatrix, 0, sizeof(int)*totalElements) != cudaSuccess) {
		cerr << "Couldn,t initialiZe device Average Matrix";
		cudaFree(dMatrix);
		cudaFree(dAvgMatrix);
	}

	const dim3 blockSize(4, 4);
	const dim3 gridSize((MATRIX_SIZE + blockSize.x - 1) / blockSize.x, (MATRIX_SIZE + blockSize.y - 1) / blockSize.y);
	int count = (RADIUS * 2 + 1)*(RADIUS * 2 + 1);

	int sharedMemSpace = (blockSize.x+2*RADIUS)*(blockSize.y+2*RADIUS) ;
	
	findAverage <<<gridSize, blockSize, sharedMemSpace * sizeof(int) >>> (dMatrix, dAvgMatrix, MATRIX_SIZE, MATRIX_SIZE, RADIUS, count, sharedMemSpace);

	cudaDeviceSynchronize();

	if (cudaGetLastError() != cudaSuccess) {
		cerr << "kernel launch failed: " << cudaGetErrorString(cudaGetLastError());
		cudaFree(dMatrix);
		cudaFree(dAvgMatrix);
		exit(1);
	}

	if (cudaMemcpy(avgMatrix, dAvgMatrix, sizeof(int)*totalElements, cudaMemcpyDeviceToHost) != cudaSuccess) {
		cerr << "Couldn't copy original matrix memory from device to host";
		cudaFree(dMatrix);
		cudaFree(dAvgMatrix);
		exit(1);
	}

	cout << endl << endl;
	for (int i = 0; i < MATRIX_SIZE; i++) {
		for (int j = 0; j < MATRIX_SIZE; j++) {
			cout << matrix[i][j] << " ";
		}
		cout << endl;
	}

	cout << endl<<endl;
	for (int i = 0; i < MATRIX_SIZE; i++){
		for (int j = 0; j < MATRIX_SIZE; j++) {
			cout << avgMatrix[i][j] << " ";
		}
		cout << endl;
	}


    return 0;
}
