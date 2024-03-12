#!/usr/bin/env zsh
set -e
SERIAL=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
RESULTS="benchmark-results-${SERIAL}"
rm -rf $RESULTS
rm -rf venv
mkdir -p $RESULTS
CORES=$(sysctl -n hw.ncpu)
python3 "$HOME"/osio-tools/scibench/mach_info.py --results "$RESULTS"
BENCH_PATH="$HOME"/osio-tools/scibench/benches

echo "[INFO] Running scientific python benchmarks"
python3 -m venv venv && source venv/bin/activate && python3 -m pip install -U pip
python3 -m pip install -U scikit-learn 'scikit-image[data]' matplotlib numpy scipy

echo "[INFO] running python image benchmarks"
IMRESULTS="${RESULTS}/python-image-benchmarks.json"
hyperfine "python3 ${BENCH_PATH}/image-bench.py"\
  --runs 10 \
  --warmup 2 \
  --export-json "${IMRESULTS}"

echo "[INFO] running python scikit learn benchmarks"
MLRESULTS="${RESULTS}/ml-benchmarks.json"
hyperfine "python3 ${BENCH_PATH}/ml-bench.py"\
  --runs 10 \
  --warmup 2 \
  --export-json "${MLRESULTS}"

echo "[INFO] Python benchmarks done."
echo "[INFO] Running sysbench benchmarks"
HALF_CORES=$(($CORES / 2))

# cpu
hyperfine "sysbench cpu run --threads=${HALF_CORES}" \
  --runs 10 \
  --export-json "${RESULTS}/sysbench-cpu.json"

# mem
hyperfine "sysbench memory run --threads=${HALF_CORES}" \
  --runs 10 \
  --export-json "${RESULTS}/sysbench-mem.json"

# mem
hyperfine "sysbench mutex run --threads=${HALF_CORES}" \
  --runs 10 \
  --export-json "${RESULTS}/sysbench-mutex.json"

echo "[INFO] Done"

