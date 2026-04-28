#include "common.h"
#include <pthread.h>

int THREADS = 4;
int *A, *B, *C;

void* worker(void* arg) {
    int id = *(int*)arg;
    int start = id * (N / THREADS);
    int end = (id == THREADS - 1) ? N : (id + 1) * (N / THREADS);

    for (int i = start; i < end; i++) {
        for (int j = 0; j < N; j++) {
            for (int k = 0; k < N; k++) {
                C[i*N + j] += A[i*N + k] * B[k*N + j];
            }
        }
    }

    return NULL;
}

int main(int argc, char *argv[]) {
    if (argc > 1) {
        THREADS = atoi(argv[1]);
    }

    pthread_t threads[THREADS];
    int ids[THREADS];

    A = malloc(sizeof(int) * N * N);
    B = malloc(sizeof(int) * N * N);
    C = malloc(sizeof(int) * N * N);

    init_matrix(A);
    init_matrix(B);

    double total = 0.0;
    long long checksum = 0;

    printf("Pthreads thread count: %d\n", THREADS);

    for (int run = 1; run <= RUNS; run++) {
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

        double t = elapsed_time(start, end);
        checksum = checksum_matrix(C);
        total += t;

        printf("Run %d: %f seconds, checksum: %lld\n", run, t, checksum);
    }

    printf("Average time over %d runs: %f seconds\n", RUNS, total / RUNS);
    printf("Final checksum: %lld\n", checksum);

    free(A); free(B); free(C);
    return 0;
}