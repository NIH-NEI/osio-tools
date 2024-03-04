#!/usr/bin/env zsh
python3 -m pip install -U scikit-learn 'scikit-image[data]' matplotlib numpy scipy

RESULTS="python-benchmarks"
rm -rf $RESULTS
mkdir -p $RESULTS
echo "[INFO] running image benchmarks"
IMRESULTS="${RESULTS}/image-benchmarks.json"
hyperfine 'python3 image-bench.py' --runs 10 --warmup 2 --export-json "${IMRESULTS}"

echo "[INFO] running scikit learn benchmarks"
MLRESULTS="${RESULTS}/ml-benchmarks.json"
hyperfine 'python3 ml-bench.py' --runs 10 --warmup 2 --export-json "${MLRESULTS}"

