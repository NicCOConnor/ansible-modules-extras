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
$params = Parse-Args $args;

$result = New-Object psobject @{
    changed = $false
}
If ($params.name)
{
	$name = $params.name
}
Else
{
	Fail-Json $result "missing required argument: name"
}

If($params.restart)
{
	$restart = $params.restart | ConvertTo-Bool
}
Else
{
	$restart = $false
}
#Set the Hostname by way of Powershell module 
$curName = [System.Net.Dns]::GetHostName()
#Make sure the name needs to be changed.
if ($curName -eq $name)
{
    $result.changed = $false
}
Else
{ 
    If ($restart)
    {
        Rename-Computer -NewName $name -Restart -Force
    }
    Else
    {
        Rename-Computer -NewName $name
    }
    $result.changed = $true
}
Exit-Json $result

