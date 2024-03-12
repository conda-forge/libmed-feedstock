#!/bin/bash

cd tests

# Compile the test program
gcc -I$CONDA_PREFIX/include test_med_int_size.c -o test_med_int_size -lmed

# Run the test and check output
./test_med_int_size
