param(
    [string]$gdrive,
    [string]$csvFile
)


$sds = "\\neivast.nei.nih.gov\data\osio_admin\test"

If(!(test-path $storage\$sds_folder))
{
    Write-Host "Error: $storage\$sds_folder does not exist"
    Exit
}

# Read the CSV file
$csvData = Import-Csv -Path $csvFile | select source_path, destination_path
#$csvData = $csvDataRaw | ForEach-Object {$_ -replace "/","\"}

# Sort the data based on the second column
$sortedData = $csvData | Sort-Object source_path

# Group by unique value for source_path
$uniqueValues = $sortedData | Group-Object source_path

write-host "DEBUG: Unique Loop"
# Loop through each unique value
foreach ($value in $uniqueValues) {
    # Get the number of repetitions for the current value
    $repetitionsCount = $value.Count
    $src = join-path -Path "$gdrive" -ChildPath "$($value.Group.source_path[0])"
    $dst = join-path -Path "$sds" -ChildPath "$($value.Group.destination_path[0])"

    Write-Host "DEBUG: count: $($value.Count)  source: $($value.Group.source_path[0]) dest: $($value.Group.destination_path[0])"
    
    #create folder path if it doesn't exist yet
    If(!(test-path (Split-Path -Path  "$dst")))
    {
        New-Item -Path (Split-Path -Path  "$dst")
    }
    
    
    Write-Host "DEBUG: copy $src $dst"
    Copy-Item "$src" "$dst"
    If(!(test-path "$dst"))
    {
        Write-Host "Error: $dst does not exist"
        Exit
    }

    # Perform a loop for the number of repetitions
    for ($i = 1; $i -lt $value.Count; $i++) {
        $srci = $src+"($i)"
        $dsti = $dst+"($i)"
        Write-Host "DEBUG: copy $srci $dsti"
        #Copy-Item "$srci" "$dsti"
        If(!(test-path "$dsti"))
        {
            #Write-Host "Error: $dsti does not exist"
            #Exit
        }
    }
}

