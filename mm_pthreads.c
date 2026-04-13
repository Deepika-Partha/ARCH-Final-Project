#include "common.h"
#include <pthread.h>

#define THREADS 4

int *A, *B, *C;

void* worker(void* arg) {
    int id = *(int*)arg;
    int start = id * (N / THREADS);
    int end = (id + 1) * (N / THREADS);

    for (int i = start; i < end; i++) {
        for (int j = 0; j < N; j++) {
            for (int k = 0; k < N; k++) {
                C[i*N + j] += A[i*N + k] * B[k*N + j];
            }
        }
    }
    return NULL;
}

int main() {
    pthread_t threads[THREADS];
    int ids[THREADS];

    A = malloc(sizeof(int)*N*N);
    B = malloc(sizeof(int)*N*N);
    C = malloc(sizeof(int)*N*N);

    init_matrix(A);
    init_matrix(B);
    zero_matrix(C);

    struct timespec start, end;
    clock_gettime(CLOCK_MONOTONIC, &start);

    for (int i = 0; i < THREADS; i++) {
        ids[i] = i;
        pthread_create(&threads[i], NULL, worker, &ids[i]);
    }

    for (int i = 0; i < THREADS; i++) {
        pthread_join(threads[i], NULL);
    }

    clock_gettime(CLOCK_MONOTONIC, &end);
    print_time(start, end);

    free(A); free(B); free(C);
    return 0;
}