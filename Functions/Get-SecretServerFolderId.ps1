###########
#region ### global:Get-SecretServerFolderId # Gets the Secret Server Folder Id specified by name.
###########
function global:Get-SecretServerFolderId
{
    <#
    .SYNOPSIS
    Gets the Secret Server Folder Id, specified by name.

    .DESCRIPTION
	This function returns the Secret Server Folder Id when provided with a string name. This function will return
	the IDs of any named folders found, and return $false if no folders are found.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns a System.Int32 number for a single folder found, a System.Int32 array for multiple folders
	found, and $false for no folders found.

    .PARAMETER Name
    The Secret Server Folder to search by name.

	.EXAMPLE
    C:\PS> Get-SecretServerFolderId -Name "My Personal Folder"
    This function will return the FolderID of the folder named "My Personal Folder". If this folder does not exist, then
	it will return $false.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $false, HelpMessage = "The name of the Folder to search/get.", ParameterSetName = "Name")]
        [System.String]$Name
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# make the search
	if ($id = Invoke-SecretServerAPI -APICall ("api/v1/folders/lookup?filter.searchText={0}" -f $Name))
	{
		# if found, return only the number Id
		return $id.records | Select-Object -ExpandProperty Id
	}

	# otherwise return $false
	return $false
}# function global:Get-SecretServerFolderId
#endregion
###########