#!/usr/bin/env bash
# Bootstrap scientific benchmarking environment for MacOS (ARM64)
# The point of this script is to ensure the system's python3 pip 
# bin is on the system path, so we can install ansible using 
set -e

PY_PATH=$HOME/Library/Python/$(python3 -c "import sys;print(f'{sys.version_info[0]}.{sys.version_info[1]}')")/bin
TARGET_PATH="$PY_PATH:${PATH}"

if grep -Fq "$PY_PATH" "$HOME/.zprofile"
then
  :
else
  export PATH=$TARGET_PATH && printf "#added for perf bootstrap setup\nexport PATH=\"%s\"\n" "$TARGET_PATH" >> "$HOME/.zprofile"
fi

if grep -Fq "$PY_PATH" <<<"$PATH"
then
  :
else
  export PATH="$TARGET_PATH"
fi

echo "[INFO] installing ansible"
python3 -m pip install -U pip
python3 -m pip install ansible
echo "[INFO] installing ansible galaxy community general collection"
ansible-galaxy collection install community.general
ansible-playbook scibench/initial-config.yml --ask-become-pass
