/*
// IN PROGRESS
#include <stdio.h>
#define N 1024

__global__ void matmul(int *A, int *B, int *C) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < N && col < N) {
        int sum = 0;
        for (int k = 0; k < N; k++) {
            sum += A[row*N + k] * B[k*N + col];
        }
        C[row*N + col] = sum;
    }
}

int main() {
    
    return 0;
}
*/

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <cuda_runtime.h>

#define N 1024
#define RUNS 5

#define CUDA_CHECK(call) do {                                      \
    cudaError_t err = call;                                        \
    if (err != cudaSuccess) {                                      \
        fprintf(stderr, "CUDA error at %s:%d: %s\n",               \
                __FILE__, __LINE__, cudaGetErrorString(err));      \
        exit(EXIT_FAILURE);                                        \
    }                                                             \
} while (0)

double elapsed_seconds(struct timespec start, struct timespec end) {
    return (end.tv_sec - start.tv_sec) +
           (end.tv_nsec - start.tv_nsec) / 1000000000.0;
}

void init_matrix(float *A, float *B) {
    srand(10);

    for (int i = 0; i < N * N; i++) {
        A[i] = (float)(rand() % 10);
        B[i] = (float)(rand() % 10);
    }
}

double checksum_matrix(float *C) {
    double sum = 0.0;

    for (int i = 0; i < N * N; i++) {
        sum += C[i];
    }

    return sum;
}

__global__ void matmul_naive_kernel(float *A, float *B, float *C, int n) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < n && col < n) {
        float sum = 0.0f;

        for (int k = 0; k < n; k++) {
            sum += A[row * n + k] * B[k * n + col];
        }

        C[row * n + col] = sum;
    }
}

__global__ void matmul_tiled_kernel(float *A, float *B, float *C, int n, int tileSize) {
    extern __shared__ float shared[];

    float *tileA = shared;
    float *tileB = shared + tileSize * tileSize;

    int tx = threadIdx.x;
    int ty = threadIdx.y;

    int row = blockIdx.y * tileSize + ty;
    int col = blockIdx.x * tileSize + tx;

    float sum = 0.0f;

    for (int tile = 0; tile < n; tile += tileSize) {
        int aCol = tile + tx;
        int bRow = tile + ty;

        if (row < n && aCol < n) {
            tileA[ty * tileSize + tx] = A[row * n + aCol];
        } else {
            tileA[ty * tileSize + tx] = 0.0f;
        }

        if (bRow < n && col < n) {
            tileB[ty * tileSize + tx] = B[bRow * n + col];
        } else {
            tileB[ty * tileSize + tx] = 0.0f;
        }

        __syncthreads();

        for (int k = 0; k < tileSize; k++) {
            sum += tileA[ty * tileSize + k] * tileB[k * tileSize + tx];
        }

        __syncthreads();
    }

    if (row < n && col < n) {
        C[row * n + col] = sum;
    }
}

void run_naive(float *d_A, float *d_B, float *d_C, float *h_C, int blockSize) {
    dim3 block(blockSize, blockSize);
    dim3 grid((N + blockSize - 1) / blockSize,
              (N + blockSize - 1) / blockSize);

    double totalTime = 0.0;
    double finalChecksum = 0.0;

    for (int r = 0; r < RUNS; r++) {
        CUDA_CHECK(cudaMemset(d_C, 0, N * N * sizeof(float)));

        struct timespec start, end;

        clock_gettime(CLOCK_MONOTONIC, &start);

        matmul_naive_kernel<<<grid, block>>>(d_A, d_B, d_C, N);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaDeviceSynchronize());

        clock_gettime(CLOCK_MONOTONIC, &end);

        totalTime += elapsed_seconds(start, end);

        CUDA_CHECK(cudaMemcpy(h_C, d_C, N * N * sizeof(float), cudaMemcpyDeviceToHost));
        finalChecksum = checksum_matrix(h_C);
    }

    printf("Naive,%d,%.6f,%.0f\n", blockSize, totalTime / RUNS, finalChecksum);
}

void run_tiled(float *d_A, float *d_B, float *d_C, float *h_C, int tileSize) {
    dim3 block(tileSize, tileSize);
    dim3 grid((N + tileSize - 1) / tileSize,
              (N + tileSize - 1) / tileSize);

    size_t sharedMemSize = 2 * tileSize * tileSize * sizeof(float);

    double totalTime = 0.0;
    double finalChecksum = 0.0;

    for (int r = 0; r < RUNS; r++) {
        CUDA_CHECK(cudaMemset(d_C, 0, N * N * sizeof(float)));

        struct timespec start, end;

        clock_gettime(CLOCK_MONOTONIC, &start);

        matmul_tiled_kernel<<<grid, block, sharedMemSize>>>(d_A, d_B, d_C, N, tileSize);
        CUDA_CHECK(cudaGetLastError());
        CUDA_CHECK(cudaDeviceSynchronize());

        clock_gettime(CLOCK_MONOTONIC, &end);

        totalTime += elapsed_seconds(start, end);

        CUDA_CHECK(cudaMemcpy(h_C, d_C, N * N * sizeof(float), cudaMemcpyDeviceToHost));
        finalChecksum = checksum_matrix(h_C);
    }

    printf("Tiled,%d,%.6f,%.0f\n", tileSize, totalTime / RUNS, finalChecksum);
}

int main() {
    size_t bytes = N * N * sizeof(float);

    float *h_A = (float *)malloc(bytes);
    float *h_B = (float *)malloc(bytes);
    float *h_C = (float *)malloc(bytes);

    init_matrix(h_A, h_B);

    float *d_A;
    float *d_B;
    float *d_C;

    CUDA_CHECK(cudaMalloc((void **)&d_A, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_B, bytes));
    CUDA_CHECK(cudaMalloc((void **)&d_C, bytes));

    CUDA_CHECK(cudaMemcpy(d_A, h_A, bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_B, h_B, bytes, cudaMemcpyHostToDevice));

    int sizes[] = {4, 8, 16, 32};
    int count = sizeof(sizes) / sizeof(sizes[0]);

    printf("Version,BlockSize,AvgTimeSeconds,Checksum\n");

    for (int i = 0; i < count; i++) {
        run_naive(d_A, d_B, d_C, h_C, sizes[i]);
    }

    for (int i = 0; i < count; i++) {
        run_tiled(d_A, d_B, d_C, h_C, sizes[i]);
    }

    CUDA_CHECK(cudaFree(d_A));
    CUDA_CHECK(cudaFree(d_B));
    CUDA_CHECK(cudaFree(d_C));

    free(h_A);
    free(h_B);
    free(h_C);

    return 0;
}