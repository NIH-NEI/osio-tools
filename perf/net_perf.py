#!/usr/bin/env python3

import sys
import subprocess

RED = '\033[0;31m'
GREEN = '\033[0;32m'
BOLD = '\033[1m'
RESET = '\033[0m'

if len(sys.argv) < 3:
    print("Usage: python3 net_perf.py <target> <wallplate>")
    print("<target> = Server IP Address or Hostname")
    print("<wallplate> = Wallplate ID Number")
    exit(1)

TARGET = sys.argv[1]
WALLPLATE = sys.argv[2]

flags = [
    '',
    '-P 2',
    '-P 7',
    '-R',
    '-R -P 2',
    '-R -P 7',
    '-i 0.5 -O 2',
    '-i 0.5 -O 2 -P 7',
    '-u -b 0',
    '-u -b 0 -P 2',
    '-u -b 0 -P 7'
]

IPERF = f'iperf3 -c {TARGET} -V'
MESSAGE = "Running iperf3 from client to server"
OUTPUT = f'bioteam_{WALLPLATE}-{TARGET}.txt'

def run_command(command):
    subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def main():
    run_command(f'ping -c 60 -s 8000 -D {TARGET} >> {OUTPUT}')
    run_command(f'traceroute {TARGET} &> /dev/null >> {OUTPUT}')

    for flag in flags:
        run_command(f'{IPERF} {flag} >> {OUTPUT}')

if __name__ == '__main__':
    main()
