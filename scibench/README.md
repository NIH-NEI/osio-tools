# Scientific Benchmarking Configuration and Tests
## Docker cask debugging
Running into some issues with installing docker cask.
One useful function is to remove the broken links docker leaves behind via:
`find <BREW_PREFIX/bin/> -xtype l -delete -print`

This should work (tested on intel mac), but note the user still has to start the docker desktop app before using. It would be great if we could run these tools with podman, that may be worth investigating.

## Configuration
The `bootstrap.sh` script will configure a MacOS system for scientific benchmark tests by configuring python, homebrew, installing ansible (via system python) and running the playbook [initial-config.yml](initial-config.yml)
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
Start a new shell to source all the environment variables created by the ansible playbook.

This step also requires an internet connection to download the nextflow pipelines.

```
# run nextflow benchmarks (should take <10min)
./nextflow/bench.sh
```

## Results

TODO(nick) Results will be:
