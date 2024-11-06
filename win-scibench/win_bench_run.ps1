
# Create the Benchmark folder on the C: drive
$benchmarkFolder = "C:\Benchmark"
Write-Host "Creating the Benchmark folder..."
New-Item -Path $benchmarkFolder -ItemType Directory -Force
Write-Host "Benchmark folder created."

# Clone the required repositories
Write-Host "Cloning osio-tools repository..."
cd $benchmarkFolder
git clone https://github.com/NIH-NEI/osio-tools.git
Write-Host "osio-tools repository cloned."

Write-Host "Cloning Phoronix-Test-Suite repository..."
git clone https://github.com/phoronix-test-suite/phoronix-test-suite.git
Write-Host "Phoronix-Test-Suite repository cloned."

# Run phoronix-test-suite.bat
Write-Host "Running Phoronix-Test-Suite setup..."
cd "$benchmarkFolder\phoronix-test-suite"
Start-Process "phoronix-test-suite.bat" -Wait
Write-Host "Phoronix-Test-Suite setup completed."

# Install scimark2 via Phoronix Test Suite
Write-Host "Installing scimark2 test via Phoronix Test Suite..."
Start-Process "phoronix-test-suite.bat" -ArgumentList "install scimark2" -Wait
Write-Host "scimark2 test installed."

# Run python-benchmarks.bat
Write-Host "Running Python benchmarks..."
cd "$benchmarkFolder\osio-tools\win-scibench\benches"
Start-Process "python-benchmarks.bat" -Wait
Write-Host "Python benchmarks completed."

# Copy the results folder to C:\Benchmark
Write-Host "Copying results folder to Benchmark directory..."
New-Item -Path "$benchmarkFolder\results" -ItemType Directory -Force
Copy-Item -Path "$benchmarkFolder\osio-tools\win-scibench\benches\python-benchmarks" -Destination "$benchmarkFolder\results" -Recurse -Force
Write-Host "Results folder copied successfully."

# Run scimark2 benchmark via Phoronix Test Suite
Write-Host "Running scimark2 benchmark via Phoronix Test Suite..."
cd "$benchmarkFolder\phoronix-test-suite"
Start-Process "phoronix-test-suite.bat" -ArgumentList "benchmark scimark2" -Wait
Write-Host "scimark2 benchmark completed."

# Prompt user for test result name
$testResultName = Read-Host "Enter the name of the test result (without extension)"

# Generate PDF from results
Write-Host "Generating PDF from test results..."
Start-Process "phoronix-test-suite.bat" -ArgumentList "result-file-to-pdf $testResultName" -Wait
Write-Host "PDF generated successfully."

# Copy the PDF result to C:\Benchmark\results
Write-Host "Copying PDF result to Benchmark results folder..."
New-Item -Path "$benchmarkFolder\results\PTS-results" -ItemType Directory -Force
Copy-Item -Path "$env:HOMEPATH\$testResultName.pdf" -Destination "$benchmarkFolder\results\PTS-results" -Force
Write-Host "PDF result copied successfully."

Write-Host "Benchmarking complete. Please check results before copying to SDS."
