# Scientific Benchmarking Configuration and Tests

Modified scripts from Mac benchmarking folder with added install and run scripts.

## Configuration
1.	Connect the new machine to the internet (make sure this is an unobstructed/guest connection, if on NIHNet, may need to download certificates from nihdpkicrl.nih.gov/CertData) and manually boot/configure with a local “test” admin account (you will also need to create this account for the post-image testing).
2.	Copy files win_bench_install.ps1 and win_bench_run.ps1.
3.	Run PowerShell script win_bench_install.ps1 as admin and follow prompts as needed.
4.	If running from command line or PowerShell window, once script has finished, close window and open new window (otherwise next script with not recognize new environmental variables).
5.	Download and install the Novabench software as this needs to be done manually.

## Running benchmarks
1.	Run win_bench_run.ps1 and follow prompts as needed:  For the Phoronix Test Suite, select option “7” to run all tests (sometimes need to hit enter twice) and “y” to save results. You do not need to view results in webpage or upload to internet but do note the name you give to the test results when prompted as you will need to enter them later.
2.	Copy results from C:\Benchmark\results folder once it has completed and place in folder named after the computer model in \Osio-tools\Benchmarks folder on SDS.
3.	Run Novabench and view results in a webpage once complete.
4.	Print results page as a PDF and copy files to the same results folder on SDS.
5.	Also, record the results in the “Benchmark Results.xlsx” spreadsheet in the Benchmarks folder on SDS.
6.  Repeat with same workstation after NEI image has been installed. Note: if you are unable to run the scripts due to policy restrictions after the computer has been imaged, you may temporarily bypass the restriction from an elevated command prompt with the command “powershell.exe -executionpolicy unrestricted [PowerShell script including full path]”.

