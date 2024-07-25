$RED = "`e[0;31m"
$GREEN = "`e[0;32m"
$BOLD = "`e[1m"
$RESET = "`e[0m"

if ($args.Count -lt 2) {
    Write-Host "Usage: .\net_perf.ps1 <target> <wallplate>"
    Write-Host "<target> = Server IP Address or Hostname"
    Write-Host "<wallplate> = Wallplate ID Number"
    exit 1
}

$TARGET = $args[0]
$WALLPLATE = $args[1]

$flags = @(
    ""
    "-P 2"
    "-P 7"
    "-R"
    "-R -P 2"
    "-R -P 7"
    "-i 0.5 -O 2"
    "-i 0.5 -O 2 -P 7"
    "-u -b 0"
    "-u -b 0 -P 2"
    "-u -b 0 -P 7"
)

$IPERF = "iperf3 -c $TARGET -V"
$MESSAGE = "Running iperf3 from client to server"
$OUTPUT = "bioteam_$WALLPLATE-$TARGET.txt"

Write-Host -NoNewline "$RED$BOLD ...Running jumbo frame ping test`n$RESET"
Write-Host -NoNewline "...Running jumbo frame ping test`n" | Out-File -Append $OUTPUT
ping -n 30 -l 8000 -4 $TARGET | Tee-Object -Append $OUTPUT

Write-Host -NoNewline "$RED$BOLD ...Running ping test`n$RESET"
Write-Host -NoNewline "...Running ping test`n" | Out-File -Append $OUTPUT
ping -n 30 $TARGET | Tee-Object -Append $OUTPUT

Write-Host -NoNewline "$RED$BOLD ...Running traceroute test`n$RESET"
Write-Host -NoNewline "...Running traceroute test`n" | Out-File -Append $OUTPUT
tracert $TARGET | Tee-Object -Append $OUTPUT

foreach ($flag in $flags) {
    Write-Host -NoNewline "$RED$BOLD ...Running iperf3 with $flag`n$RESET"
    Write-Host -NoNewline "...Running iperf3 with $flag`n" | Out-File -Append $OUTPUT
    Invoke-Expression "$IPERF $flag" | Tee-Object -Append $OUTPUT
}
