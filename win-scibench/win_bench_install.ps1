
# Function to get the latest release download URL from GitHub using Invoke-RestMethod
function Get-LatestReleaseUrl {
    param (
        [string]$repoName,  # e.g., 'sharkdp/hyperfine'
        [string]$assetPattern # Pattern to match the asset you want, e.g., '*.zip' for Hyperfine
    )

    # Fetch the latest release data from the GitHub API
    $url = "https://api.github.com/repos/$repoName/releases/latest"
    $headers = @{ "User-Agent" = "PowerShell-Script" }
    
    # Get the latest release data from the GitHub API using Invoke-RestMethod
    $releaseInfo = Invoke-RestMethod -Uri $url -Headers $headers

    # Find the asset that matches the given pattern
    $latestAsset = $releaseInfo.assets | Where-Object { $_.name -like $assetPattern }

    if ($latestAsset) {
        # Extract the download URL
        $downloadUrl = $latestAsset.browser_download_url

        # Extract the file name from the URL
        $fileName = Split-Path -Leaf $downloadUrl

        # Remove the .zip extension from the file name
        $fileNameWithoutZip = $fileName -replace '\.zip$', ''

        return $fileNameWithoutZip, $downloadUrl
    } else {
        Write-Host "No matching asset found for $repoName with pattern $assetPattern"
        return $null
    }
}

# Function to check if Hyperfine is installed
function Check-Hyperfine {
    $hyperfinePath = (Get-Command hyperfine -ErrorAction SilentlyContinue).Source
    if ($hyperfinePath) {
        Write-Host "Hyperfine is already installed at $hyperfinePath."
        return $true
    }
    else {
        Write-Host "Hyperfine is not installed."
        return $false
    }
}

# Function to check if Git is installed
function Check-Git {
    $gitCheck = git --version -ErrorAction SilentlyContinue
    if ($gitCheck) {
        Write-Host "Git is already installed."
        return $true
    }
    else {
        Write-Host "Git is not installed."
        return $false
    }
}

# Function to check if PHP is installed
function Check-Php {
    $phpCheck = Get-Command php -ErrorAction SilentlyContinue
    if ($phpCheck) {
        Write-Host "PHP is already installed."
        return $true
    }
    else {
        Write-Host "PHP is not installed."
        return $false
    }
}

# Function to install Python
{
    Write-Host "Installing Python..."
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstallerPath = "$env:TEMP\python-installer.exe"
    Start-BitsTransfer -Source $pythonUrl -Destination $pythonInstallerPath
    Start-Process $pythonInstallerPath -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait
    Write-Host "Python installed successfully."
}

 # Install Python

# Copy python.exe to python3.exe in case script is looking for python3
$pythonInstallPath = "C:\Program Files\Python312"  # Modify this path based on the actual Python installation directory
$pythonExePath = Join-Path -Path $pythonInstallPath -ChildPath "python.exe"
$python3ExePath = Join-Path -Path $pythonInstallPath -ChildPath "python3.exe"

if (Test-Path $pythonExePath) {
    Copy-Item -Path $pythonExePath -Destination $python3ExePath
    Write-Host "Created a copy of python.exe as python3.exe"
} else {
    Write-Host "Error: python.exe not found in $pythonInstallPath"
}


# Check and install Hyperfine if not installed
if (-not (Check-Hyperfine)) {
    Write-Host "Fetching the latest version of Hyperfine..."
    $result = Get-LatestReleaseUrl -repoName "sharkdp/hyperfine" -assetPattern "hyperfine-*-x86_64-pc-windows-msvc.zip"
    $fileNameWithoutZip = $result[0]
    $downloadUrl = $result[1]
    
    if ($downloadUrl) {
        $hyperfineZipPath = "$env:TEMP\hyperfine.zip"
        $hyperfineExtractPath = "$env:TEMP\$fileNameWithoutZip"
        $hyperfineUnzipPath = Join-Path -Path $hyperfineExtractPath -ChildPath $fileNameWithoutZip

        # Download Hyperfine zip
        Start-BitsTransfer -Source $downloadUrl -Destination $hyperfineZipPath

        # Extract Hyperfine to a temporary folder
        Expand-Archive -Path $hyperfineZipPath -DestinationPath $hyperfineExtractPath -Force

        # Define the path to the hyperfine.exe inside the extracted folder
        $extractedExePath = Join-Path -Path $hyperfineUnzipPath -ChildPath "hyperfine.exe"

        # Check if the executable exists in the extracted folder
        if (Test-Path $extractedExePath) {
            Write-Host "Found hyperfine.exe in the extracted folder."

            # Move the executable to a folder in the system PATH (e.g., C:\Program Files\Hyperfine)
            $hyperfineInstallPath = "C:\Program Files\Hyperfine"
            New-Item -Path $hyperfineInstallPath -ItemType Directory -Force
            Move-Item -Path $extractedExePath -Destination $hyperfineInstallPath

            # Add Hyperfine to the system PATH
            $env:Path += ";$hyperfineInstallPath"
            [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)

            Write-Host "Hyperfine installed successfully."
        } else {
            Write-Host "Error: Could not find hyperfine.exe in the extracted folder."
        }
    }
}

# Check and install Git if not installed
if (-not (Check-Git)) {
    Write-Host "Fetching the latest version of Git..."
    $gitResult = Get-LatestReleaseUrl -repoName "git-for-windows/git" -assetPattern "*64-bit.exe"
    $fileNameWithoutZip = $gitResult[0]
    $gitUrl = $gitResult[1]

    if ($gitUrl) {
        $gitInstallerPath = "$env:TEMP\git-installer.exe"

        # Download Git installer
        Start-BitsTransfer -Source $gitUrl -Destination $gitInstallerPath

        # Install Git silently
        Start-Process -FilePath $gitInstallerPath -ArgumentList '/silent' -Wait
        Write-Host "Git installed successfully."
    }
}

# Check and install PHP if not installed
if (-not (Check-Php)) {
    Write-Host "Installing PHP..."

    # Fetch the HTML content of the PHP Windows downloads page
    $phpDownloadsPage = Invoke-RestMethod -Uri "https://windows.php.net/download/" -Headers @{ "User-Agent" = "PowerShell-Script" }

    # Use a regex pattern to match the latest stable Windows installer link (64-bit thread-safe)
    $pattern = 'href="(\/downloads\/releases\/php-[\d.]+-nts-Win32-vs16-x64\.zip)"'
    if ($phpDownloadsPage -match $pattern) {
        # Extract the matched download link and construct the full URL
        $downloadUrl = "https://windows.php.net" + $matches[1]
        Write-Host "Found PHP download URL: $downloadUrl"

        # Download the latest PHP package
        $phpZipPath = "$env:TEMP\php-latest.zip"
        Start-BitsTransfer -Source $downloadUrl -Destination $phpZipPath

        # Extract PHP to a destination directory
        $phpInstallPath = "C:\php"
        New-Item -Path $phpInstallPath -ItemType Directory -Force
        Expand-Archive -Path $phpZipPath -DestinationPath $phpInstallPath -Force

        Write-Host "PHP has been installed in $phpInstallPath"

        # Add PHP to the system PATH
        $env:Path += ";$phpInstallPath"
        [Environment]::SetEnvironmentVariable("Path", $env:Path, [EnvironmentVariableTarget]::Machine)

        Write-Host "PHP has been added to the system PATH."
    } else {
        Write-Host "Unable to find the latest PHP version download link."
    }
}
