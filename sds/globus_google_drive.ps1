param(
    [string]$gdrive,
    [string]$csvFile
)


function grename ($path, $i) {
    $basename = [IO.Path]::GetFileNameWithoutExtension($path)
    $extension = [IO.Path]::GetExtension($path)
    $fdir = [IO.Path]::GetDirectoryName($path)
    $newname = "$fdir\$basename ($i)$extension"
    return $newname
}


$sds = "\\neivast.nei.nih.gov\data\osio_admin\test"

If(!(test-path $sds))
{
    Write-Host "Error: $sds does not exist"
    Exit
}

# Read the CSV file
$csvData = Import-Csv -Path $csvFile | select source_path, destination_path


# Sort the data based on the second column
$sortedData = $csvData | Sort-Object source_path

# Group by unique value for source_path
$uniqueValues = $sortedData | Group-Object source_path

write-host "DEBUG: Unique Loop"
# Loop through each unique value
foreach ($value in $uniqueValues) {
    # Get the number of repetitions for the current value
    #$repetitionsCount = $value.Count
    if ($value.count -eq 1)
    {
        $src = join-path -Path "$gdrive" -ChildPath "$($value.Group.source_path)"
        $dst = join-path -Path "$sds" -ChildPath "$($value.Group.destination_path)"
    }
    else
    {
        $src = join-path -Path "$gdrive" -ChildPath "$($value.Group.source_path[0])"
        $dst = join-path -Path "$sds" -ChildPath "$($value.Group.destination_path[0])"
    }

    Write-Host "DEBUG: count: $($value.Count)  source: $($value.Group.source_path[0]) dest: $($value.Group.destination_path[0])"
    
    If(!(test-path "$src"))
    {
        Write-Host "Error: Source $src does not exist"
        Exit
    }

    #create folder path if it doesn't exist yet
    If(!(test-path (Split-Path -Path  "$dst")))
    {
        New-Item -Path (Split-Path -Path  "$dst")
    }
    # if destination file already exists on SDS (maybe previous copy operation)
    if (test-path "$dst")
    {
        Write-Host "Warning destination file $dst already exists, type y to overwrite"
        $choice = Read-Host

        if ($choice -ne "y") 
        {
            Write-host "Will not overwrite, please manually clean up destination file and re-run this script"
            Exit
        }

    }
    
    Write-Host "DEBUG: copy $src $dst"
    Copy-Item "$src" "$dst"
    If(!(test-path "$dst"))
    {
        Write-Host "Error: Copy Failed - Destination $dst does not exist"
        Exit
    }

    # Perform a loop for the number of repetitions
    for ($i = 1; $i -lt $value.Count; $i++) {
        $srci = grename $src $i
        $dsti = grename $dst $i

        If(!(test-path "$srci"))
        {
            Write-Host "Error: Source $srci does not exist"
            Exit
        }

        Write-Host "DEBUG: copy $srci $dsti"
        Copy-Item "$srci" "$dsti"
        If(!(test-path "$dsti"))
        {
            Write-Host "Error: Copy Failed - Destination $dsti does not exist"
            Exit
        }
    }
}

