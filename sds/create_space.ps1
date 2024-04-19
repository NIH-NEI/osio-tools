
#Storage Path
$storage = "\\neivast.nei.nih.gov\data\"

Import-Module ActiveDirectory
# Define the function for user lookup in AD
# the function returns user object that is then used for ACLs on the directory
function Lookup-User($iname) {
    # Check if the input contains @ symbol
    if ($iname -match "@") {
        # Assume the input is an email and search for the user in Active Directory using the email
        $user = Get-ADUser -Filter {EmailAddress -eq $iname -or UserPrincipalName -eq $iname } -Properties samAccountName, SID, Department, gecos, UserPrincipalName
    }
    else {
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
    Write-Error "User not found in Active Directory for input: $iname"
    }
}






#Get folder path
Write-Host "Enter the folder to create"
$space = Read-Host

if ($space -eq "") {
Write-Host "No folder specified, exiting"
Exit
}

$spacepath=$storage+$space

If(!(test-path $spacepath))
{

    #get owner
    $name = Read-Host "Enter the name of the folder owner"
    $owner = Lookup-User "$name"

    Write-Host "Confirm creation of new space: $spacepath "
    Write-Host "Owner:" $owner.gecos " " $owner.samAccountName "(y/n)"

    $choice = Read-Host

    if ($choice -eq "y")
    {
   
        #$corespath=$storage+$space+"\cores"

        # Create full access rule for NEI SDS IT SysAdmin group
        $groupSID = (Get-ADGroup "NEI SDS IT SysAdmin").SID
        $groupPrincipal = New-Object System.Security.Principal.SecurityIdentifier($groupSID)
        $groupAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($groupPrincipal, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")

        # create folder
        $folder = New-Item -ItemType Directory -Path  $spacepath

        # Get the current access control list (ACL) of the folder
        $folderACL = $folder.GetAccessControl()
        # Disable inheritance removing all ACLs
        $folderACL.SetAccessRuleProtection($true, $false)
        # Set full permissions for NEI SDS IT SysAdmin group
        $folderACL.AddAccessRule($groupAccessRule)
        # Set owner
        $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($owner.SID)
        $folderACL.SetOwner($userPrincipal)

       

        $names = Read-Host  "Enter the user names who should have full permissions"        

        # Split the input by comma and trim any whitespace
        $inputs = $names -split "," | ForEach-Object {$_.Trim()}

        # Add full permissions ACLs
        foreach ($name in $inputs) {
            $user = Lookup-User($name)
            Write-Host "Full permissions for: " $user.samAccountName
            $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
            $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
            $folderACL.AddAccessRule($userAccessRule)
        }

        $names = Read-Host  "Enter the user names who should have Read/Write permissions"        

        # Split the input by comma and trim any whitespace
        if ($names) { $inputs = $names -split "," | ForEach-Object {$_.Trim()}

        # Add Modify permissions ACLs
         foreach ($name in $inputs) {
            $user = Lookup-User($name)
            Write-Host "Modify permissions for: " $user.samAccountName
            $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
            $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "Modify", "ContainerInherit, ObjectInherit", "None", "Allow")
            $folderACL.AddAccessRule($userAccessRule)
        }
        }

        $names = Read-Host "Enter the user names who should have Read Only permissions"        

        # Split the input by comma and trim any whitespace
        if ($names) { $inputs = $names -split "," | ForEach-Object {$_.Trim()}

        # Add ReadAndExecute permissions ACLs
         foreach ($name in $inputs) {
            $user = Lookup-User($name)
            Write-Host "ReadExecute permissions for: " $user.samAccountName
            $userPrincipal = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
            $userAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userPrincipal, "ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")
            $folderACL.AddAccessRule($userAccessRule)
        }
        }

        $folder.SetAccessControl($folderACL)
    }

}
else
{
    Write-Host "Error: $spacepath already exists"
}