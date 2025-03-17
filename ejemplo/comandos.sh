#!/bin/bash
cd '/home/usuario/Escritorio/Boston1'
/usr/bin/make -s -f nbproject/Makefile-Debug.mk build/Debug/GNU-Linux/src/main.o
mkdir -p build/Debug/GNU-Linux/src
rm -f "build/Debug/GNU-Linux/src/main.o.d"
g++ -Wall -pedantic   -c -g -Wall -Iinclude -std=c++14 -MMD -MP -MF "build/Debug/GNU-Linux/src/main.o.d" -o build/Debug/GNU-Linux/src/main.o src/main.cpp
g++ -Wall -pedantic    -o dist/Debug/GNU-Linux/boston1 build/Debug/GNU-Linux/src/ArrayCrimesFunctions.o build/Debug/GNU-Linux/src/Coordinates.o build/Debug/GNU-Linux/src/Crime.o build/Debug/GNU-Linux/src/DateTime.o build/Debug/GNU-Linux/src/main.o
