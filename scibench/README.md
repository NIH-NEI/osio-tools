# Scientific Benchmarking Configuration and Tests

## Configuration
The `bootstrap.sh` script will configure a MacOS system for scientific benchmark tests by configuring python, homebrew, installing ansible (via system python) and running the playbook [initial-config.yml](scibench/initial-config.yml)
It installs the following:
- homebrew
- Java (OpenJDK 11)
- Docker (not yet)
- nextflow (>=23.10)

On a fresh or factory reset computer, create the user account, connect to the internet, then run the following to install Mac Developer tools:

```
xcode-select --install
```

Now, we can run the 'bootstrap' script.
Note that this script will prompt you for the system password to install homebrew, which we will be using to install all the dependencies.

```bash
./scibench/bootstrap.sh
# <enter password>
```

## Running Nextflow benchmarks
_not yet functional/automated_

This step also requires an internet connection to download the nextflow pipelines.

```
# run nextflow benchmarks (should take <10min)
./nextflow/bench.sh
```

## Results

TODO(nick) Results will be:
