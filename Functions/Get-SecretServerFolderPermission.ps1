###########
#region ### global:Get-SecretServerFolderPermission # Gets the Secret Server Folder Permission specified by folder id.
###########
function global:Get-SecretServerFolderPermission
{
    <#
    .SYNOPSIS
    Gets the Secret Server Folder Permissions, specified by the Folder ID.

    .DESCRIPTION
	This function returns the Secret Server Folder Permissions when provided with a Folder ID. This function will return
	the permission information of principals who have permission access to this folder, and return $false if no folders are found.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns a PSCustomObject array with each principal permission being an element in that array, or $false for 
	principal permissions found.

    .PARAMETER Id
    The Secret Server Folder ID to find permissions.

	.EXAMPLE
    C:\PS> Get-SecretServerFolderPermission -Id 4
    This function will return the principal permissions stack of the folder with a folder ID of 4. If no principal permissions
	exist, then it will return $false.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $false, HelpMessage = "The Id of the Folder to search/get.", ParameterSetName = "Id")]
        [System.String]$Id
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# make the search
	if ($results = Invoke-SecretServerAPI -APICall ("api/v1/folder-permissions?filter.folderId={0}" -f $Id))
	{
		# if found, return only the records
		return $results.records
	}

	# otherwise return $false
	return $false
}# function global:Get-SecretServerFolderPermission
#endregion
###########