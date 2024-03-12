# Scientific Benchmarking Configuration and Tests

This should work (tested on intel mac), but note the user still has to start the docker desktop app before using. It would be great if we could run these tools with podman, that may be worth investigating.

## Configuration
The `bootstrap.sh` script will configure a MacOS system for scientific benchmark tests by configuring python, homebrew, installing ansible (via system python) and running the playbook [initial-config.yml](initial-config.yml)
It installs the following:
- homebrew
- Java (OpenJDK 11)
- nextflow (>=23.10)

On a fresh or factory reset computer, create the user account, connect to the internet, then run the following to install Mac Developer tools:

```
xcode-select --install
```

Now, we can clone the osio-tools repository and run the 'bootstrap' script.
Note that this script will prompt you for the system password to install homebrew, which we will be using to install all the dependencies.

```bash
git clone https://github.com/NIH-NEI/osio-tools.git
cd osio-tools
./scibench/bootstrap.sh
# <enter password>
```

Note, you will have to manually install/configure Docker, that is not functioning automatically.

## Running benchmarks
Start a new shell to source all the environment variables created by the ansible playbook.

This step also requires an internet connection to download the nextflow pipelines and data for other benchmarks.


```
./runall.sh
```
this is a driver script that will run:
- nextflow sarek benchmark
- sysbench benchmarks
- Scientific python benchmarks for image processing and ML

## Results

TODO(nick) Results will be:
