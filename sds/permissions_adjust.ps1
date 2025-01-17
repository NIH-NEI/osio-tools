Import-Module ActiveDirectory
# Define the function for user lookup in AD
# the function returns user object that is then used for ACLs on the directory
function Lookup-User {
    param (
        [string]$iname
    )
    # Check if the input contains @ symbol
    if ($iname -match "@") {
        # Assume the input is an email and search for the user in Active Directory using the email
        $user = Get-ADUser -Filter {EmailAddress -eq $iname -or UserPrincipalName -eq $iname } -Properties samAccountName, SID, Department, gecos, UserPrincipalName
        if (-not $user) {
            $user = Get-ADGroup -Filter {EmailAddress -eq $iname } -Properties samAccountName, SID, Department, gecos, UserPrincipalName
        }
    }
    elseif ($iname -notmatch " ") {
        # Assume the input is a username since it has no space or @
        $user = Get-ADUser -Filter {samAccountName -eq $iname } -Properties samAccountName, SID, Department, gecos, UserPrincipalName
        if (-not $user) {
            $user = Get-ADGroup -Filter {samAccountName -eq $iname -or cn -eq $iname} -Properties samAccountName, SID, Department, gecos, UserPrincipalName
        }

    }
    else {
        #Check to see if this is a group since these can have spaces in them...
        $user = Get-ADGroup -Filter {samAccountName -eq $iname -or cn -eq $iname} -Properties samAccountName, SID, Department, gecos, UserPrincipalName
        if (-not $user) {
        # Assume the input is a first and last name and split the input by space
        $name = $iname -split " "
        # Assign the first and last name variables
        $FirstName = $name[0]
        # Last name takes into account possible multi-word names
        $LastName = $name[1..($name.Length - 1)]
        # Genrate a string to match DisplayName for the times when GivenName doesn't match Prefered name
        $sstr = "${LastName}, ${FirstName} (NIH*"

        # Search for the user in Active Directory using DisplayName or full name (gecos)
        $user = Get-ADUser -Filter {DisplayName -like $sstr -or gecos -eq $iname } -Properties samAccountName, SID, Department, gecos, UserPrincipalName
        }
    }

    # Check if the user(s) matching the name is found in AD
    if ($user) {
    # Check to see if there are multiple users that matched (same name)
        if($user.Count)
        {
            
            #this means we got an array of users, more than one user matched
            #we will cycle through the users, asking to select the correct match
            Write-Host "There were "$user.Count" users that match a name, please select the correct user (y/n)"
            foreach ($person in $user) {
                 $correct = Read-Host $person.gecos ";" $person.samAccountName "; " $person.Department
                    if ($correct -eq "y") {
                        #return the correct user object
                        Write-Host "Selected user: "$person.samAccountName
                        return $person
                    }
            }
            #no account was selected, through exeption that no user was selected
            throw "No user selected..."
        }
        else {
            #one user was matched, returning user object
            return $user
        }
    }
    else {
    # No user matched, this should not happen, return an error message
    throw "No user found in Active Directory for $iname"
    # Write-Error "User not found in Active Directory for input: $iname"
    }
}


function GetTest {
    param(
        [string]$dstring
        )
  # Variable to store what user types into Input textbox
     $debug_txt.Text = $($debug_txt.Text) + " `n " + $dstring
     $debug_txt.refresh()
# Set path to user's input
#If(test-path $folder) {
#    $folderACL =  Get-Acl -Path $folder
#    $faccess = $folderACL.Access
#    $fowner_txt.Text = $folderACL.Owner.ToString()
#  $fowner_txt.Refresh()

#  $form.Refresh()
#  }
#  Else
#{
#    $fowner_txt.Text = "$folder"
#}
  
}

function GetPermissions {

# Variable to store what user types into Input textbox
$folder = $path_txt.Text 
# Set path to user's input
If(test-path $folder) {
    $error_path.Hide()
    $ffull = ""
    $fwrite = ""
    $fread = ""
    $folderACL =  Get-Acl -Path $folder 
    $faccess = $folderACL.Access 
    $fowner_txt.Text = $folderACL.Owner.Split('\')[1]
    foreach ($accesrule in $faccess) {
     #parse the existing ACLs and populate the fields for Owner, Full, RW, Read
     $fsr = $accesrule.FileSystemRights.ToString()
     if ($fsr -match "FullControl")
     {
        #Write-Host $accesrule.IdentityReference.Value
        $ffull = $ffull + $accesrule.IdentityReference.Value.Split('\')[1] + "; "

     }
     elseif (($fsr -match "Modify") -or ($fsr -match "Write")) 
     {
        $fwright = $fwright + $accesrule.IdentityReference.Value.Split('\')[1] + "; "
     }
     elseif ($fsr -match "Read")
     {
        $fread = $fread + $accesrule.IdentityReference.Value.Split('\')[1] + "; "
     }

    }

    # Variable to store results of actioning the Input
    #$Result = $Input | Get-ChildItem | Out-String
    # Assign Result to OutputBox
    #$Outputbox.Text = $Result
    #redraw form? 
    $fowner_txt.Refresh()
    $full_txt.Text = $ffull
    $full_txt.Refresh()
    $wright_txt.Text = $fwright
    $wright_txt.Refresh()
    $read_txt.Text = $fread
    $form.Refresh()  
}
Else
{
    #$fowner_txt.Text = "Error: Unable to read the path"
    $error_path.Show()
}
 

}


function SetPermissions { 
    $folder = $path_txt.Text 
    If(test-path $folder) {
        $error_path.Hide()
        $folderACL = New-Object System.Security.AccessControl.DirectorySecurity
        $folderACL.SetAccessRuleProtection($true, $false)
        # Create full access rule for NEI SDS IT SysAdmin group
        $groupSID = (Get-ADGroup "NEI SDS IT SysAdmin").SID
        $groupPrincipal = New-Object System.Security.Principal.SecurityIdentifier($groupSID)
        #GetTest $groupPrincipal
        $groupAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupPrincipal, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
        $folderACL.AddAccessRule($groupAccessRule)

      
        $owner = Lookup-User "$($fowner_txt.Text)"
        #GetTest $owner
        $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($owner.SID)
        $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
        $folderACL.AddAccessRule($userAccessRule)
        $folderACL.SetOwner($userPrincipal)
        
        $userlist = @($userPrincipal)

        $inputs = $full_txt.Text -split ";" | ForEach-Object {$_.Trim()}
        # Add full permissions ACLs
         GetTest "Full Permissions"
        foreach ($name in $inputs -ne '') {
            $user = Lookup-User $name
            GetTest $user.samAccountName 
            
            $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)

            if( $userlist -notcontains $userPrincipal ) {
                $userlist += $userPrincipal
                Write-Host "DEBUG: Full permissions for: " $user.samAccountName
                $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $folderACL.AddAccessRule($userAccessRule)
            }
        }

        # Add Modify permissions ACLs
        if ($wright_txt.Text) { $inputs = $wright_txt.Text -split ";" | ForEach-Object {$_.Trim()}

             GetTest "Write:"
              
            foreach ($name in $inputs -ne '') {
                $user = Lookup-User $name
                GetTest $user.samAccountName 
                
                $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
                if( $userlist -notcontains $userPrincipal ) {
                    $userlist += $userPrincipal
                    Write-Host "DEBUG: Modify permissions for: " $user.samAccountName
                    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
                    $folderACL.AddAccessRule($userAccessRule)
                }
            }
        }
        # Add ReadAndExecute permissions ACLs
        # Split the input by comma and trim any whitespace
        if ($read_txt.Text) { $inputs = $read_txt.Text -split ";" | ForEach-Object {$_.Trim()}
         GetTest "Read/Execute:"
 
            foreach ($name in $inputs -ne '') {
                $user = Lookup-User $name
                GetTest $user.samAccountName 
                
                $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
                if( $userlist -notcontains $userPrincipal ) {
                    $userlist += $userPrincipal
                    Write-Host "DEBUG: ReadExecute permissions for: " $user.samAccountName
                    $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
                    $folderACL.AddAccessRule($userAccessRule)
                }
            }
        }
       Start-Sleep -Seconds 20
       #$folder.SetAccessControl($folderACL)
       Set-Acl -Path $folder -AclObject $folderACL
       #$debug_txt.Text = $folderACL
       #$debug_txt.Refresh()
       Start-Sleep -Seconds 10

  }
  Else
  {
      $error_path.Show()
  }
}

function OpenFldr {
    $folderselection = New-Object System.Windows.Forms.OpenFileDialog -Property @{  
    InitialDirectory = [Environment]::GetFolderPath('Desktop')  
    CheckFileExists = 0  
    ValidateNames = 0  
    FileName = "Choose Folder" 
    }
    $folderselection.ShowDialog()   
}  


function OpenFldr2($initialDirectory) {
[System.Reflection.Assembly]::LoadWithPartialName("system.windows.forms") | Out-Null
$foldername = New-Object System.Windows.Forms.FolderBrowserDialog
$foldername.Description = "Select a folder"
$foldername.SelectedPath = $initialDirectory
if($foldername.ShowDialog() -eq "OK") {
$folder += $foldername.SelectedPath
}
#return $folder
$path_txt.Text = $folder.ToString()
}


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog


$form = New-Object System.Windows.Forms.Form
$form.Text = 'Permissions Entry Form'
#$form.Size = New-Object System.Drawing.Size(300,650)
$form.Size = New-Object System.Drawing.Size(800,950)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,570)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,570)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$path_lbl = New-Object System.Windows.Forms.Label
$path_lbl.Location = New-Object System.Drawing.Point(10,20)
$path_lbl.Size = New-Object System.Drawing.Size(280,20)
$path_lbl.Text = 'Please enter the path for permission changes:'
$form.Controls.Add($path_lbl)

$path_txt = New-Object System.Windows.Forms.TextBox
$path_txt.Location = New-Object System.Drawing.Point(10,40)
$path_txt.Size = New-Object System.Drawing.Size(260,20)
$path_txt.Text = "\\neivast.nei.nih.gov\data\osio_admin\test\novacores"
$form.Controls.Add($path_txt)

$browse_btn = New-Object System.Windows.Forms.Button
$browse_btn.Location = New-Object System.Drawing.Point(10,60)
$browse_btn.Size = New-Object System.Drawing.Size(75,23)
$browse_btn.Text = 'Browse'
#$path_btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($browse_btn)

$path_btn = New-Object System.Windows.Forms.Button
$path_btn.Location = New-Object System.Drawing.Point(180,60)
$path_btn.Size = New-Object System.Drawing.Size(75,23)
$path_btn.Text = 'Get Permissions'
#$path_btn.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($path_btn)

$error_path = New-Object System.Windows.Forms.Label
$error_path.Location = New-Object System.Drawing.Point(10,90)
$error_path.Size = New-Object System.Drawing.Size(280,20)
$error_path.Text = 'Error: Unable to read folder path'
$error_path.Hide()
$form.Controls.Add($error_path)

$fowner_lbl =  New-Object System.Windows.Forms.Label
$fowner_lbl.Location =  New-Object System.Drawing.Point(10,100)
$fowner_lbl.Size = New-Object System.Drawing.Size(280,20)
$fowner_lbl.Text = 'Please enter Owner username:'
$form.Controls.Add($fowner_lbl)

$fowner_txt = New-Object System.Windows.Forms.TextBox
$fowner_txt.Location = New-Object System.Drawing.Point(10,120)
$fowner_txt.Size = New-Object System.Drawing.Size(260,20)
$fowner_txt.Text = "sample owner"
$form.Controls.Add($fowner_txt)


$full_lbl = New-Object System.Windows.Forms.Label
$full_lbl.Location = New-Object System.Drawing.Point(10,160)
$full_lbl.Size = New-Object System.Drawing.Size(280,20)
$full_lbl.Text = 'Please enter usernames for Full Permissions:'
$form.Controls.Add($full_lbl)

$full_txt = New-Object System.Windows.Forms.TextBox
$full_txt.Location = New-Object System.Drawing.Point(10,180)
$full_txt.Size = New-Object System.Drawing.Size(260,20)
$full_txt.Text = "sample full"
$form.Controls.Add($full_txt)


$write_lbl = New-Object System.Windows.Forms.Label
$write_lbl.Location = New-Object System.Drawing.Point(10,220)
$write_lbl.Size = New-Object System.Drawing.Size(280,20)
$write_lbl.Text = 'Please enter usernames for Wright Permissions:'
$form.Controls.Add($write_lbl)

$wright_txt = New-Object System.Windows.Forms.TextBox
$wright_txt.Location = New-Object System.Drawing.Point(10,240)
$wright_txt.Size = New-Object System.Drawing.Size(260,20)
$wright_txt.Text = "sample wright"
$form.Controls.Add($wright_txt)



$read_lbl = New-Object System.Windows.Forms.Label
$read_lbl.Location = New-Object System.Drawing.Point(10,280)
$read_lbl.Size = New-Object System.Drawing.Size(280,20)
$read_lbl.Text = 'Please enter usernames for Read Permissions:'
$form.Controls.Add($read_lbl)

$read_txt = New-Object System.Windows.Forms.TextBox
$read_txt.Location = New-Object System.Drawing.Point(10,300)
$read_txt.Size = New-Object System.Drawing.Size(260,20)
$read_txt.Text = "sample read"
$form.Controls.Add($read_txt)

$debug_txt = New-Object System.Windows.Forms.RichTextBox
$debug_txt.Location = New-Object System.Drawing.Point(300,350)
$debug_txt.Size = New-Object System.Drawing.Size(300,300)
$debug_txt.Multiline = $True
$debug_txt.Text = "Debug text"
$form.Controls.Add($debug_txt)



$form.Topmost = $true

$form.Add_Shown({$full_txt.Select()})

$browse_btn.Add_Click({OpenFldr2 $path_txt.Text})

#$Button1.Add_Click({GetPermissions})

$path_btn.Add_Click({GetPermissions})

$okButton.Add_Click({SetPermissions})

$result = $form.ShowDialog()

#if ($result -eq [System.Windows.Forms.DialogResult]::OK)
#{SetPermissions
   # $names = $full_txt.Text
   # $inputs = $names -split "," | ForEach-Object {$_.Trim()}

   # foreach ($name in $inputs) {
   #         $user = Lookup-User($name)
   #         Write-Host "Full permissions for: " $user.samAccountName
   #         $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
   #         $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
            #$folderACL.AddAccessRule($userAccessRule)
  #      }
#}