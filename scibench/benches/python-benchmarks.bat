@echo off

python3 "-m" "pip" "install" "-U" "scikit-learn" "scikit-image[data]" "matplotlib" "numpy" "scipy"
SET "RESULTS=python-benchmarks"
DEL /S "%RESULTS%"
mkdir "-p" "%RESULTS%"
echo "[INFO] running image benchmarks"
SET "IMRESULTS=%RESULTS%/image-benchmarks.json"
hyperfine "python3 image-bench.py" "--runs" "10" "--warmup" "2" "--export-json" "%IMRESULTS%"
echo "[INFO] running scikit learn benchmarks"
SET "MLRESULTS=%RESULTS%/ml-benchmarks.json"
hyperfine "python3 ml-bench.py" "--runs" "10" "--warmup" "2" "--export-json" "%MLRESULTS%"
