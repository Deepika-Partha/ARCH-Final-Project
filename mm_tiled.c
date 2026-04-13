#include "common.h"

#define TILE 32

int main() {
    int *A = malloc(sizeof(int) * N * N);
    int *B = malloc(sizeof(int) * N * N);
    int *C = malloc(sizeof(int) * N * N);

    init_matrix(A);
    init_matrix(B);
    zero_matrix(C);

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    for (int ii = 0; ii < N; ii += TILE)
        for (int jj = 0; jj < N; jj += TILE)
            for (int kk = 0; kk < N; kk += TILE)
                for (int i = ii; i < ii + TILE; i++)
                    for (int j = jj; j < jj + TILE; j++)
                        for (int k = kk; k < kk + TILE; k++)
                            C[i*N + j] += A[i*N + k] * B[k*N + j];

    clock_gettime(CLOCK_MONOTONIC, &end);
    print_time(start, end);

    free(A); free(B); free(C);
    return 0;
}