
param(
  [Parameter(Mandatory=$true)]
  [String]$sds_folder
)


$storage = "\\neivast.nei.nih.gov\data"

If(!(test-path $storage\$sds_folder))
{
    Write-Host "Error: $storage\$sds_folder does not exist"
    Exit
}

$cores = @()

$cores +=
[PSCustomObject]@{
  Path = 'biological_imaging_core'
  User = @("farissr")
}

$cores +=
[PSCustomObject]@{
  Path = 'biological_imaging_core\confocal_microscopy'
  User = @("farissr","whitend")
}

$cores +=
[PSCustomObject]@{
  Path = 'biological_imaging_core\histology'
  User = @("camposm")
}

$cores +=
[PSCustomObject]@{
  Path = 'biological_imaging_core\structural_biology'
  User = @("sagarv")
}

$cores +=
[PSCustomObject]@{
  Path = 'biological_imaging_core\transmission_electron_microscopy'
  User = @("bautistawd")
}

$cores +=
[PSCustomObject]@{
  Path = 'flow_cytometry_core'
  User = @("villasmilr")
}

$cores +=
[PSCustomObject]@{
  Path = 'genetic_engineering_core'
  User = @("dongl")
}

$cores +=
[PSCustomObject]@{
  Path = 'ocular_gene_therapy_core'
  User = @("lit4")
}

$cores +=
[PSCustomObject]@{
  Path = 'visual_function_core'
  User = @("qianh")
}




$corespath=$storage+"\"+$sds_folder+"\cores"
Write-Host "DEBUG: corespath $corespath"
If(!(test-path $corespath))
{
  New-Item -ItemType Directory -Path $corespath
}
 
$CACL = Get-Acl -Path $corespath


foreach ($core in $cores) {
  $cpath = $core.Path
  $corepath=$corespath+"\"+$core.Path

  If(!(test-path $corepath)) {
    New-Item -ItemType Directory -Path $corepath
  }
  If($core.Path.Contains("\")) {
     $sp = $core.Path -split "\\"
     $subpath = $corespath+"\"+ $sp[0]
     $SACL = Get-Acl -Path $subpath
  }

  $ACL = Get-Acl -Path $corepath
  foreach ($name in $core.User) {
    Write-Host "Permissions for: $name"
    $CoresReadRule = New-Object System.Security.AccessControl.FileSystemAccessRule($name, "ReadAndExecute", "None", "None", "Allow")
    $CoreReadWriteRule = New-Object System.Security.AccessControl.FileSystemAccessRule($name, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
    $CACL.AddAccessRule($CoresReadRule) 
    $ACL.AddAccessRule($CoreReadWriteRule)
    if($SACL) {
        $SACL.AddAccessRule($CoresReadRule)
    }
  }
  Set-Acl -Path $corepath -AclObject $ACL
  if($SACL) {
    Set-Acl -Path $subpath -AclObject $SACL
    Remove-Variable SACL
  }
}

Set-Acl -Path $corespath -AclObject $CACL



