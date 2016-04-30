#!powershell
# This file is part of Ansible.
#
# Copyright 2014, Nic O'Connor <nic.oconnor@gmail.com>
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
Function Required-Args($params,[String[]]$arguments)
{
	#Ensure that these arguments are specified
	$fail = $false
	$msg = ""
	foreach($a in $arguments)
	{
		if($params.$a -eq $null)
		{
			$fail = $true
			$msg += "$a, "
		}
	}
	if($fail)
	{
		$msg += "are required parameters"
		Fail-Json $msg
	}
}
Function Required-Together($params,[String[]]$arguments)
{
	#Ensure that these arguments are specified together
	$fail = $false
	$msg = ""
	foreach ($a in $arguments)
	{
		if($params.$a -eq $null)
		{
			$fail = $true
		}
	}
	if($fail)
	{
		$msg += $arguments -join ":, "
		$msg += ": are Required Together"
		Fail-Json $msg
	}
}
Function Required-If($params,$arg,$condition,[String[]]$req_arguments)
{
	#Function to conditionally specify parameters If one parameter is specified it's dependencies must also
	#be specified.
	$fail = $false
	$msg = ""
	if($arg -ne $null)
	{
		$arg_check = $true
		if($arg_check -eq $condition)
		{
			foreach($a in $req_arguments)
			{
				if($params.$a -eq $null)
				{
					$fail = $true
				}
			}
		}
	}
	if($fail)
	{
		#Get name of passed variable by value
		$arg_name = ($params.psobject.Properties | where {$_.value -like $arg}).Name
		
		$msg += $req_arguments -join ", "
		$msg += " are required if $arg_name is specified"
		Fail-Json $msg
	}
}
Function Mutually-Exclusive($params,[String[]]$mutually_exclusive)
{
	#Make sure that these arguments are not specified in the same run.
	$fail = $false
	$msg = ""
	$me_count = 0
	foreach($me in $mutually_exclusive)
	{
		if(Get-Param -obj $params -name $me -ne $null)
		{
			$me_count++
		}
	}
	if($me_count -gt 1)
	{
		$fail = $true
	}
	if($fail)
	{
		$msg += $mutually_exclusive -join ":, "
		$msg += " Cannot be specified together"
		Fail-Json $msg
	}
}
function Get-Param($obj, $name, $default = $null, $resultobj, $failifempty=$false, $emptyattributefailmessage, $ValidateSet, $ValidateSetErrorMessage )
{
	if (Get-Command Get-AnsibleParam -ErrorAction SilentlyContinue)
	{
		Get-AnsibleParam -obj $obj -name $name -default $default -failifempty $failifempty -emptyattributefailmessage $emptyattributefailmessage -ValidateSet $ValidateSet -ValidateSetErrorMessage $ValidateSetErrorMessage
	}
	else
	{
		# Check if the provided Member $name exists in $obj and return it or the default. 
	    Try
	    {
	        If (-not $obj.$name.GetType)
	        {
	            throw
	        }

	        if ($ValidateSet)
	        {
	            if ($ValidateSet -contains ($obj.$name))
	            {
	                $obj.$name    
	            }
	            Else
	            {
	                if ($ValidateSetErrorMessage -eq $null)
	                {
	                    #Auto-generated error should be sufficient in most use cases
	                    $ValidateSetErrorMessage = "Argument $name needs to be one of $($ValidateSet -join ",") but was $($obj.$name)."
	                }
	                Fail-Json -obj $resultobj -message $ValidateSetErrorMessage
	            }
	        }
	        Else
	        {
	            $obj.$name
	        }
	        
	    }
	    Catch
	    {
	        If ($failifempty -eq $false)
	        {
	            $default
	        }
	        Else
	        {
	            If (!$emptyattributefailmessage)
	            {
	                $emptyattributefailmessage = "Missing required argument: $name"
	            }
	            Fail-Json -obj $resultobj -message $emptyattributefailmessage
	        }
	    }
	}
}

$params = Parse-Args $args;

$result = New-Object psobject @{
    changed = $false
}
$required = "name"
$mutuallyExclusive = "domain","workgroup"
$domain_requiredIf = "domain_user","domain_pass"
$workgroup_requiredIf = "domain_user","domain_pass"

$name=$domain=$domain_user=$domain_pass=$workgroup=$restart=$null

$name = Get-Param -obj $params -name "name" -failifempty $false
$domain = Get-Param -obj $params -name "domain" -failifempty $false
$domain_user = Get-Param -obj $params -name "domain_user" -failifempty $false
$domain_pass = Get-Param -obj $params -name "domain_pass" -failifempty $false
$workgroup = Get-Param -obj $params -name "workgroup" -failifempty $false
$restart = Get-Param -obj $params -name "restart" -failifempty $false

Required-Args $params $required
Mutually-Exclusive $params $mutuallyExclusive
if($workgroup)
{
	Required-If $params $workgroup $true $workgroup_requiredIf
}

if($domain)
{
	Required-If $params $domain $true $domain_requiredIf
}

If($restart)
{
	$restart = $params.restart | ConvertTo-Bool
}
Else
{
	$restart = $false
}

#Get the hostname and domain
$curName = [System.Net.Dns]::GetHostName()
$curDomain = (gwmi win32_computersystem).domain

#if domain is specified we use another method to change the name and add it to the domain in one command
if($domain)
{
	$changeName = if($curName -ne $name){$true}else{$false}
	$changeDomain = if($curDomain -ne $domain){$true}else{$false}
	$netbiosDomain = $domain.split(".")[0]
	$secPassword = ConvertTo-SecureString $domain_pass -AsPlainText -Force
	$creds = New-Object System.Management.Automation.PSCredential("$netbiosDomain\$domain_user",$secPassword)

	if($changeName -and $changeDomain)
	{
		try
		{
			Rename-Computer -NewName $name -Force
			Add-Computer -Credential $creds -DomainName $domain -PassThru -ErrorAction Stop -Options AccountCreate,JoinWithNewName
		}
		catch
		{
			Fail-Json "$Error.Exception"
		}
		$result.changed = $true
	}
	elseif($changedomain)
	{
	try
		{
			Add-Computer -Credential $creds -DomainName $domain -PassThru -ErrorAction Stop
		}
		catch
		{
			Fail-Json "$Error.Exception"
		}
		$result.changed = $true
	}
}
elseif($workgroup)
{
	$secPassword = ConvertTo-SecureString $domain_pass -AsPlainText -Force
	$netbiosDomain = $curDomain.split(".")[0]
	$creds = New-Object System.Management.Automation.PSCredential("$netbiosDomain\$domain_user",$secPassword)
	try
	{
		Remove-Computer -UnjoinDomainCredential $creds -Force -PassThru -ErrorAction Stop
	}
	catch
	{
		Fail-Json "$Error.Exception"
	}
	$result.changed = $true
}
# Just Change the Hostname
else
{
	if($curName -ne $name)
	{
		Rename-Computer -NewName $name -Force
    	$result.changed = $true
	}
}
#only reboot if the machine has been changed.
if(($restart) -and ($result.changed))
{
	Restart-Computer -Force
}
Exit-Json $result
