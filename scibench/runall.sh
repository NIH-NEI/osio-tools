#!/usr/bin/env zsh

echo "[INFO] Running scientific python benchmarks"
./benches/python-benchmarks.sh

echo "[INFO] Running sysbench benchmarks"
./benches/sysbench-bench.sh

echo "[INFO] Running nf core benchmarks"
./benches/nf-bench.sh

echo "[INFO] Done"

