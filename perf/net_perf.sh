#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RESET='\033[0m'

if [ $# -lt 2 ]; then
  echo "Usage: ./net_perf.sh <target> <wallplate>"
  echo "<target> = Server IP Address or Hostname"
  echo "<wallplate> = Wallplate ID Number"
  exit 1
fi

TARGET=$1
WALLPLATE=$2

declare -a flags

# Disable individual iperf3 tests by commenting out flags below
   flags[0]=''
   flags[1]='-P 2'
   flags[2]='-P 7'
   flags[3]='-R'
   flags[4]='-R -P 2'
   flags[5]='-R -P 7'
   flags[6]='-i 0.5 -O 2'
   flags[7]='-i 0.5 -O 2 -P 7'
   flags[8]='-u -b 0'
   flags[9]='-u -b 0 -P 2'
   flags[10]='-u -b 0 -P 7'

IPERF="iperf3 -c $TARGET -V"
MESSAGE="Running iperf3 from client to server"
OUTPUT=bioteam_$WALLPLATE-$TARGET.txt

echo -ne "${RED}${BOLD} ...Running jumbo frame ping test\n${RESET}" && echo -ne "...Running jumbo frame ping test\n${RESET}" >> $OUTPUT && ping -c 30 -s 8000 -D $TARGET | tee -a $OUTPUT 
echo -ne "${RED}${BOLD} ...Running ping test\n${RESET}" && echo -ne "...Running ping test\n${RESET}" >> $OUTPUT && ping -c 30 $TARGET | tee -a $OUTPUT

echo -ne "${RED}${BOLD} ...Running traceroute test\n${RESET}" && echo -ne "...Running traceroute test\n${RESET}" >> $OUTPUT && traceroute $TARGET | tee -a $OUTPUT
   
for flag in "${flags[@]}"; do
	echo -ne "${RED}${BOLD} ...Running iperf3 with $flag\n${RESET}" && echo -ne "...Running iperf3 with $flag\n${RESET}" >> $OUTPUT && $IPERF $flag | tee -a $OUTPUT
done
