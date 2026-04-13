#include "common.h"

void init_matrix(int *A) {
    srand(10);
    for (int i = 0; i < N * N; i++) {
        A[i] = rand() % 10;
    }
}

void zero_matrix(int *C) {
    for (int i = 0; i < N * N; i++) {
        C[i] = 0;
    }
}

void print_time(struct timespec start, struct timespec end) {
    double time = (end.tv_sec - start.tv_sec) +
                  (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("Execution time: %f seconds\n", time);
}