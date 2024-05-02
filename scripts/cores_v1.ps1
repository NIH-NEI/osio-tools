#Cores folder structure creator v1.0

#Define the directory path and the groups

#Storage Path
$storage = "\\neivast.nei.nih.gov\data\"

#List of cores
$cores = @("histology", "confocal_microscopy", "vfc", "flow_cytometry", "ocular_gene_therapy")

#core personnel
$histology = @("camposm")
$confocal_microscopy = @("farissr","whitend")
$vfc = @("qianh")
$flow_cytometry = @("villasmilr")
$ocular_gene_therapy = @("lit4")

#Get folder path
Write-Host "Enter the folder where to setup core directories"
$space = Read-Host

if ($space -eq "") {
Write-Host "No folder specified, exiting"
Exit
}

$corespath=$storage+$space+"\cores"

Write-Host "Confirm creation of cores structure: $corespath ? (y/n)"
$choice = Read-Host

if ($choice -eq "y")
{
   

    #$corespath=$storage+$space+"\cores"

    If(!(test-path $corespath))
    {
        New-Item -ItemType Directory -Path $corespath
        $CACL = Get-Acl -Path $corespath

        foreach ($core in $cores) {
            $corepath=$corespath+"\"+$core
            If(!(test-path $corepath))
            {
                New-Item -ItemType Directory -Path $corepath
                $ACL = Get-Acl -Path $corepath
                $usernames = Get-Variable $core -valueonly
                foreach ($name in $usernames) {
                    Write-Host "Permissions: $name"
                    $CoresReadRule = New-Object System.Security.AccessControl.FileSystemAccessRule($name, "ReadAndExecute", "None", "None", "Allow")
                    $CoreReadWriteRule = New-Object System.Security.AccessControl.FileSystemAccessRule($name, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
                    $CACL.AddAccessRule($CoresReadRule) 
                    $ACL.AddAccessRule($CoreReadWriteRule)


                }
                Set-Acl -Path $corepath -AclObject $ACL
            }

        }

        Set-Acl -Path $corespath -AclObject $CACL


    }
}