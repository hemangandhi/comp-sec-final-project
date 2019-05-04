#!/bin/bash
# chmod +x build-example.sh
# ./build-example.sh

trap "exit" INT

kelinciPath="/home/heman/Documents/undergrad/security/final-proj/kelinci/instrumentor/build/libs/kelinci.jar"

echo "Create KelinciWCA folder and copy files"
mkdir -p ./kelinciwca_analysis/src
cp SampleSym.java ./kelinciwca_analysis/src
mkdir -p ./kelinciwca_analysis/bin
cp SampleSym.class ./kelinciwca_analysis/bin

echo "Create SymExe folder and copy files"
mkdir -p ./symexe_analysis/src
cp SampleSym.java ./symexe_analysis/src
mkdir -p ./symexe_analysis/bin
cp SampleSym.class ./symexe_analysis/bin

echo "Instrument Kelinci code"
cd ./kelinciwca_analysis
java -jar $kelinciPath -i ./bin/ -o ./bin-instr #-skipmain

echo "Done."