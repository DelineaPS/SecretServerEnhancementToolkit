###########
#region ### global:ConvertFrom-DataToSecretServerFolder # Converts stored data back into a SecretServerFolder object with class methods
###########
function global:ConvertFrom-DataToSecretServerFolder
{
    <#
    .SYNOPSIS
    Converts SecretServerFolder-data back into a SecretServerFolder object. Returns an ArrayList of SecretServerFolder class objects.

    .DESCRIPTION
    This function will take data that was created from a SecretServerFolder class object, and recreate that SecretServerFolder
    class object that has all available methods for a SecretServerFolder object. This is returned as an ArrayList of SecretServerFolder
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataFolders
    Provides the data for SecretServerFolder.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of SecretServerFolder class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToSecretServerFolder -DataFolders $DataFolders
    Converts SecretServerFolder-data into a SecretServerFolder class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The SecretServerFolder data to convert to a SecretServerFolder object.")]
        [PSCustomObject[]]$DataFolders
    )

	# a new ArrayList to return
	$NewSecretServerFolders = New-Object System.Collections.ArrayList

	# for each set object in our Data data
    foreach ($secretserverfolder in $DataFolders)
    {
        # new empty SecretServerFolder object
        $obj = New-Object SecretServerFolder -ArgumentList $secretserverfolder

        # add this object to our return ArrayList
        $NewSecretServerFolders.Add($obj) | Out-Null
    }# foreach ($secretserverfolder in $DataFolders)

    # return the ArrayList
    return $NewSecretServerFolders
}# function global:ConvertFrom-DataToSecretServerFolder
#endregion
###########