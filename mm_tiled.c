#include "common.h"

int main(int argc, char *argv[]) {
    int TILE = 32;

    if (argc > 1) {
        TILE = atoi(argv[1]);
    }

    int *A = malloc(sizeof(int) * N * N);
    int *B = malloc(sizeof(int) * N * N);
    int *C = malloc(sizeof(int) * N * N);

    init_matrix(A);
    init_matrix(B);

    double total = 0.0;
    long long checksum = 0;

    printf("Tile size: %d\n", TILE);

    for (int run = 1; run <= RUNS; run++) {
        zero_matrix(C);

        struct timespec start, end;
        clock_gettime(CLOCK_MONOTONIC, &start);

        for (int ii = 0; ii < N; ii += TILE) {
            for (int jj = 0; jj < N; jj += TILE) {
                for (int kk = 0; kk < N; kk += TILE) {
                    for (int i = ii; i < ii + TILE && i < N; i++) {
                        for (int j = jj; j < jj + TILE && j < N; j++) {
                            for (int k = kk; k < kk + TILE && k < N; k++) {
                                C[i*N + j] += A[i*N + k] * B[k*N + j];
                            }
                        }
                    }
                }
            }
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