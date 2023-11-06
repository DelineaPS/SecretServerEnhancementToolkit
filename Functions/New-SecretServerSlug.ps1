###########
#region ### global:New-SecretServerSlug # Creates a new Secret Server slug
###########
function global:New-SecretServerSlug
{
    <#
    .SYNOPSIS
    Creates a new Secret Server slug, used for other Secret Server objects.

    .DESCRIPTION
	This function will create a Secret Server slug based on the parameter input.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns SecretServerSlug object.

    .PARAMETER slug
    Sets the name of the slug.

	.PARAMETER value
	Sets the value of the slug.

	.EXAMPLE
    C:\PS> New-SecretServerSlug -slug domain -value "domain.com"
	This function will create a new SecretServerSlug object with the name of the slug being "domain", and the
	value of the slug being "domain.com.

	#>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the slug.")]
		[System.String]$slug,

		[Parameter(Mandatory = $true, HelpMessage = "The value of the slug.")]
		[System.String]$value
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# building the slug
	$obj = New-Object SecretServerSlug -ArgumentList ($slug, $value)

	return $obj
}# function global:New-SecretServerSlug
#endregion
###########