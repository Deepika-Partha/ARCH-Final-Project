#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 1024
#define RUNS 5

void init_matrix(int *A);
void zero_matrix(int *C);
double elapsed_time(struct timespec start, struct timespec end);
long long checksum_matrix(int *C);

#endif