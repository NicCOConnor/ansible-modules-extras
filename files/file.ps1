#!powershell
# This file is part of Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;

function Set-Permissions
{
    Param (
        [string]$path,
        [string]$mode = "0644",
        [string]$user = "sgadmin",
        [string]$group
    )

    $changed = $false
    $permissions = [convert]::ToInt32($mode, 8)
    $permBits = @()
    $permBits += ( $permissions -band 0x07 )
    $permBits += ( ( $permissions -shr 3 ) -band 0x07 )
    $permBits += ( ( $permissions -shr 6 ) -band 0x07 )

    $perms = @()

    foreach ( $permBit in $permBits )
    {
        $perm = @()
        if ($permBit -band 0x04)
        {
            $perm += "Read"
        }
        if ($permBit -band 0x02)
        {
            $perm += "Write"
        }
        if ($permBit -band 0x01)
        {
            $perm += "Execute"
        }
        $perms += , $perm
    }


    Write-Verbose "Setting the Permissions to $( $perms -join ', ' )"
    # Setting up the ACL object
    $rights = [System.Security.AccessControl.FileSystemRights]$perms
    $inherit = [System.Security.AccessControl.InheritanceFlags]::None
    $propogate = [System.Security.AccessControl.PropogationFlags]::None
    $objType = [System.Security.AccessControl.AccessControlType]::Allow
    $objUser = New-Object System.Security.Principal.NTAccount( $user )
    $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
        ($objUser, $rights, $inherit, $propogate, $objType )

    $origAcl = Get-Acl -path $path
    $origACL.RemoveAccessRuleAll($objACE)
    Set-Acl $path $objAcl -ErrorVariable $work

    $work

    #foreach ( $access in $origAcl.access )
    #{
    #    foreach ( $idRef in $access.IdentityReference.Value )
    #    {
    #        $defaults = @( "NT Authority\System", "BUILTIN\sgadmin" )
    #        if ( $defaults -notcontains $idRef )
    #        {
    #            if ( $idRef -eq $user )
    #            {
    #                $origAcl.RemoveAccessRule( $access ) | Out-Null
    #        }
    #    }
    #}
    ## Applying the removal of the old
    #Set-Acl -path $path -aclObject $origAcl

}

# path
$path = Get-Attr $params "path" $FALSE;
If ($path -eq $FALSE)
{
    $path = Get-Attr $params "dest" $FALSE;
    If ($path -eq $FALSE)
    {
        $path = Get-Attr $params "name" $FALSE;
        If ($path -eq $FALSE)
        {
            Fail-Json (New-Object psobject) "missing required argument: path";
        }
    }
}

# state - file, link, directory, hard, touch, absent
$state = Get-Attr $params "state" "file";

$src = Get-Attr $params "src";

# recurse - yes, no
$recurse = Get-Attr $params "recurse" "no";

# force - yes, no
$force = Get-Attr $params "force" "no";

# group
$group = Get-Attr $params "group";

# acl
$acl = Get-Attr $params "acl";

# owner
$owner = Get-Attr $params "owner";

# mode
$mode = Get-Attr $params "mode";



# result
$result = New-Object psobject @{
    changed = $FALSE
    mode = $mode
    owner = $owner
    group = $group
    acl = $acl
};

If ( $state -eq "touch" )
{
    If(Test-Path $path)
    {
        (Get-ChildItem $path).LastWriteTime = Get-Date
    }
    Else
    {
        echo $null > $file
    }
    $result.changed = $TRUE;
}

If (Test-Path $path)
{
    If ( $state -eq "absent" )
    {
        Remove-Item $path -Force;
        $result.changed = $TRUE;
    }
    Else
    {
        # Translate perms to windows
        $info = Get-Item $path;
        # Only files have the .Directory attribute.
        If ( $state -eq "directory" -and $info.Directory )
        {
            Fail-Json (New-Object psobject) "path is not a directory";
        }
        #else
        #{
        #    $result.acl = Set-Permissions $path $mode $env:computername + "\" + $user
        #}
        # Only files have the .Directory attribute.
        If ( $state -eq "file" -and -not $info.Directory )
        {
            Fail-Json (New-Object psobject) "path is not a file";
        }
        #else
        #{
        #    $result.acl = Set-Permissions $path $mode $env:computername + "\" + $user
        #}
    }
}
Else
{
    If ( $state -eq "directory" )
    {
        New-Item -ItemType directory -Path $path
    }

    If ( $state -eq "file" )
    {
        Fail-Json (New-Object psobject) "path will not be created";
    }
}

Exit-Json $result;