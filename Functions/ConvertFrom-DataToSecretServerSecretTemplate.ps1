###########
#region ### global:ConvertFrom-DataToSecretServerSecretTemplate # Converts stored data back into a SecretServerSecretTemplate object with class methods
###########
function global:ConvertFrom-DataToSecretServerSecretTemplate
{
    <#
    .SYNOPSIS
    Converts SecretServerSecretTemplate-data back into a SecretServerSecretTemplate object. Returns an ArrayList of SecretServerSecretTemplate class objects.

    .DESCRIPTION
    This function will take data that was created from a SecretServerSecretTemplate class object, and recreate that SecretServerSecretTemplate
    class object that has all available methods for a SecretServerSecretTemplate object. This is returned as an ArrayList of SecretServerSecretTemplate
    class objects.

	The data provided could be in JSON/XML, or a PSCustomObject format.

    .PARAMETER DataSecretTemplates
    Provides the data for SecretServerSecretTemplate.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs an ArrayList of SecretServerSecretTemplate class objects.

    .EXAMPLE
    C:\PS> ConvertFrom-DataToSecretServerSecretTemplate -DataSecretTemplates $DataSecretTemplates
    Converts SecretServerSecretTemplate-data into a SecretServerSecretTemplate class object.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The SecretServerSecretTemplate data to convert to a SecretServerSecretTemplate object.")]
        [PSCustomObject[]]$DataSecretTemplates
    )

	# a new ArrayList to return
	$NewSecretServerSecretTemplates = New-Object System.Collections.ArrayList

	# for each set object in our Data data
    foreach ($SecretServerSecretTemplate in $DataSecretTemplates)
    {
        # new empty SecretServerSecretTemplate object
        $obj = New-Object SecretServerSecretTemplate -ArgumentList $SecretServerSecretTemplate

        # add this object to our return ArrayList
        $NewSecretServerSecretTemplates.Add($obj) | Out-Null
    }# foreach ($SecretServerSecretTemplate in $DataSecretTemplates)

    # return the ArrayList
    return $NewSecretServerSecretTemplates
}# function global:ConvertFrom-DataToSecretServerSecretTemplate
#endregion
###########