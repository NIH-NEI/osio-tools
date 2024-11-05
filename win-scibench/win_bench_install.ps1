# Function to download the latest certificates from NIH and install them
function Get-NIHCerts {
    $certDataUrl = 'http://nihdpkicrl.nih.gov/CertData'
	$Destination = 'C:\Certificates'
	$Pattern = '*.crt'
	
	#Create download directory for certificates.
	New-Item -ItemType Directory -Path $Destination -Force | Out-Null
	
    try {
		$webResponse = Invoke-WebRequest -Uri $certDataUrl -UseBasicParsing
	} catch {
		Write-Error "Failed to connect to $certDataUrl"
	return
	}
	
	#Filter and download files based on certPattern
	$files = $webResponse.Links | Where-Object { $_.href -like $Pattern }
	#List found certificates
	Write-Host "Certificates found:"
	foreach ($file in $files) {
		$fileName = [System.IO.Path]::GetFileName($file.href)
		Write-Host $fileName
	}

	foreach ($file in $files) {
		$fileName = [System.IO.Path]::GetFileName($file.href)
		$fileUrl = "$certDataUrl/$fileName"
		$destinationPath = Join-Path -Path $Destination -ChildPath $fileName
		
		try {
			#Download the file
			Start-BitsTransfer -Source $fileUrl -Destination $destinationPath
			#Invoke-WebRequest -Uri $fileUrl -Outfile $destinationPath
			Write-Output "Downloaded: $fileName to $destinationPath"
		} catch {
			Write-Error "Failed to download $fileName"
		}

	# Install the certificate in both Root and CA stores for Current User and Local Machine
        try {
            # Install to Current User Root and CA stores
            Import-Certificate -FilePath $destinationPath -CertStoreLocation Cert:\CurrentUser\Root
            Write-Output "Installed $fileName to Current User Root store"
            
            Import-Certificate -FilePath $destinationPath -CertStoreLocation Cert:\CurrentUser\CA
            Write-Output "Installed $fileName to Current User CA store"

            # Install to Local Machine Root and CA stores (requires admin privileges)
            Import-Certificate -FilePath $destinationPath -CertStoreLocation Cert:\LocalMachine\Root
            Write-Output "Installed $fileName to Local Machine Root store"
            
            Import-Certificate -FilePath $destinationPath -CertStoreLocation Cert:\LocalMachine\CA
            Write-Output "Installed $fileName to Local Machine CA store"
        } catch {
            Write-Error "Failed to install $fileName"
        }
	}
}

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
    $gitCheck = Get-Command git -ErrorAction SilentlyContinue
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

# Function to download and rename Cygwin setup file for Phoronix
function downloadCygwin {
    Write-Host "Downloading Cygwin..."
    $CWUrl = "https://cygwin.com/setup-x86_64.exe"
    $CWInstallerPath = "$HOME\Downloads\cygwin-setup-x86_64.exe"
    Start-BitsTransfer -Source $CWUrl -Destination $CWInstallerPath
    Write-Host "Cygwin downloaded successfully."
}

# Function to install Python
function installPython {
    Write-Host "Installing Python..."
    $pythonUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
    $pythonInstallerPath = "$env:TEMP\python-installer.exe"
    Start-BitsTransfer -Source $pythonUrl -Destination $pythonInstallerPath
    Start-Process $pythonInstallerPath -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait
	# Copy python.exe to python3.exe in case script is looking for python3
		$pythonInstallPath = "C:\Program Files\Python312"  # Modify this path based on the actual Python installation directory
		$pythonScriptPath = "C:\Program Files\Python312\Scripts"
		$pythonExePath = Join-Path -Path $pythonInstallPath -ChildPath "python.exe"
		$python3ExePath = Join-Path -Path $pythonInstallPath -ChildPath "python3.exe"
		if (Test-Path $pythonExePath) {
			Copy-Item -Path $pythonExePath -Destination $python3ExePath
			Write-Host "Created a copy of python.exe as python3.exe"
		} else {
			Write-Host "Error: python.exe not found in $pythonInstallPath"
		}
	# Add Python to system PATH and move to top of list
	[System.Environment]::SetEnvironmentVariable("Path", "$pythonInstallPath;$([System.Environment]::GetEnvironmentVariable('Path', 'Machine'))", "Machine")
	[System.Environment]::SetEnvironmentVariable("Path", "$pythonScriptPath;$([System.Environment]::GetEnvironmentVariable('Path', 'Machine'))", "Machine")
    Write-Host "Python installed successfully."
}

# Download NIH certificates
 Get-NIHCerts

# Download Cygwin
 downloadCygwin
 
 # Install Python
 installPython

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
    [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
    $phpDownloadsPage = Invoke-RestMethod -Uri "https://windows.php.net/download/" -Headers @{ "User-Agent" = "PowerShell-Script" }

    # Use a regex pattern to match the latest stable Windows installer link (64-bit thread-safe)
    $pattern = 'href="(\/downloads\/releases\/php-[\d.]+-nts-Win32-vs16-x64\.zip)"'
    if ($phpDownloadsPage -match $pattern) {
        # Extract the matched download link and construct the full URL
        $downloadUrl = "https://windows.php.net" + $matches[1]
        Write-Host "Found PHP download URL: $downloadUrl"

        # Download the latest PHP package
        $phpZipPath = "$env:TEMP\php-latest.zip"
        # Fails due to Tls issue: Start-BitsTransfer -Source $downloadUrl -Destination $phpZipPath
        Invoke-WebRequest $phpUrl -OutFile $phpZipPath

        # Extract PHP to a destination directory
        $phpInstallPath = "C:\PHP"
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
