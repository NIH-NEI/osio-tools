# Scientific Benchmarking Configuration and Tests

## Configuration
The `bootstrap.sh` script will configure a MacOS system for scientific benchmark tests by configuring python, installing ansible (via system python) and running the playbook [initial-config.yml](scibench/initial-config.yml)
It installs the following:
- homebrew
- Java (OpenJDK > v11)
- Docker
- nextflow (>=23.10)

Note the script will prompt you for the system password to install homebrew.

```bash
./scibench/bootstrap.sh
# <enter password>
```

## Running
Requires an internet connection to download the nextflow pipelines.

```
# run nextflow benchmarks (should take <10min)
./nextflow/bench.sh
```

## Results

TODO(nick) Results will be:
