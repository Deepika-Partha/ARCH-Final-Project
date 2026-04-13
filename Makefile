CC=gcc

all: base tiled pthreads openmp

base:
	$(CC) -O0 mm_base.c common.c -o base

tiled:
	$(CC) -O0 mm_tiled.c common.c -o tiled

pthreads:
	$(CC) -O0 mm_pthreads.c common.c -lpthread -o pthreads

openmp:
	$(CC) -O0 mm_openmp.c common.c -fopenmp -o openmp

clean:
	rm -f base tiled pthreads openmp