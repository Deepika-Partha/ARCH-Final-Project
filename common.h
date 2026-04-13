#ifndef COMMON_H
#define COMMON_H

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define N 1024

void init_matrix(int *A);
void zero_matrix(int *C);
void print_time(struct timespec start, struct timespec end);

#endif