# **How to use net_perf:**

.\net_perf(.sh/.ps1/.py) "ip-address" "WAO #" 

## **Description:**

This script does three major events. It first checks jumbo frame pinging, then checks regular pings, then runs the command iperf3 to selected IP address with a variety of flags. Please consult this documentation for flag information: https://iperf.fr/iperf-doc.php 

While running the command, the output is "tee-ed" to a folder which hosts all of the outputs. This folder will appear in the same directory as the script, and the naming convention is "bioteam_'WAO #'_'IP'"



