#include <ctime>
#include <stdlib.h>
#include <iostream>

__device__ int sum_neighbors(int* board, int r, int c, int n) {
	int sum = 0;
	for(int i = r-1; i < r+2; i++) {
		for(int j = c-1; j < c+2; j++) {
			if((i != r) || (j != c)) {
				sum += board[i*n+j];
			}
		}
	}
	return sum;
}

__global__ void tick(int* board_in, int* board_out, int n) {
	
	//int my_index = (blockDim.x+2)*(blockIdx.x+1) + threadIdx.x+1;
	int row = blockIdx.x+1; //plus one to account for border remaining constant. blocks/threads index the inner matrix
	int col = threadIdx.x+1;
	if(board_in[row*n+col]){
		if(sum_neighbors(board_in, row, col, n)==2 || sum_neighbors(board_in, row, col, n)==3){
			board_out[row*n+col] = 1;
		}
		else{
			board_out[row*n+col] = 0;
		}
	}
	else{
		if(sum_neighbors(board_in, row, col, n)==3){
			board_out[row*n+col] = 1;
		}
		else{
			board_out[row*n+col] = 0;
		}
	}
}


int main(int argc, char* argv[]) {
	srand((unsigned) time(0));

	int n = atoi(argv[1]);
	int rounds = atoi(argv[2]);
	int* board_even = new int[n*n];
	int* board_odd = new int[n*n];
	

	//initialize random board
	for(int i = 0; i < n*n; i++) {
		board_even[i] = rand()%2;
		board_odd[i] = board_even[i];
	}
	//kill border, border stays dead
	for(int x = 0; x < n; x++) {
		board_even[x] = 0;
		board_even[(n-1)*n + x] = 0;
		board_even[x*n] = 0;
		board_even[x*n+n-1]=0;
		board_odd[x]=0;
		board_odd[(n-1)*n+x]=0;
		board_odd[x*n]=0;
		board_odd[x*n+n-1]=0;
	}

	int *board_even_d, *board_odd_d;
	cudaMalloc(&board_even_d, n*n*sizeof(int));
	cudaMalloc(&board_odd_d, n*n*sizeof(int));

	cudaMemcpy(board_even_d, board_even, n*n*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(board_odd_d, board_odd, n*n*sizeof(int), cudaMemcpyHostToDevice);
	
	//check initial state, run 1 evolution, check end state
	
	for(int i = 0; i < n; i++){
                for(int j = 0; j < n; j++){
                        std::cout<<board_even[i*n+j]<<" ";
                }
                std::cout<<"\n";
        }
	std::cout<<"\n";

	for(int r = 0; r < rounds; r++) {
		//evolve
		if (r%2==0){
			tick<<<n-2, n-2>>>(board_even_d, board_odd_d, n);
		}
		else {
			tick<<<n-2, n-2>>>(board_odd_d, board_even_d, n);
		}
	}

	cudaMemcpy(board_odd, board_odd_d, n*n*sizeof(int), cudaMemcpyDeviceToHost);
	cudaMemcpy(board_even, board_even_d, n*n*sizeof(int), cudaMemcpyDeviceToHost);
	
	for(int i = 0; i < n; i++){
		for(int j = 0; j < n; j++) {
			std::cout<<board_odd[i*n+j]<<" ";
		}
		std::cout<<"\n";
	}
	std::cout<<"\n";

	for(int i = 0; i < n; i++){
		for(int j = 0; j < n; j++){
			std::cout<<board_even[i*n+j]<<" ";
		}
		std::cout<<"\n";
	}

	cudaFree(board_even_d);
	cudaFree(board_odd_d);
	delete[] board_even;
	delete[] board_odd;
	return 0;
}