###########
#region ### global:Get-SecretServerSite # Gets Secret Server Sites from the Secret Server instance
###########
function global:Get-SecretServerSite
{
    <#
    .SYNOPSIS
    Gets Secret Server Sites from the connected Secret Server instance.

    .DESCRIPTION
	This function will get Secret Server Sites from the connected Secret Server instance, and process them into
	SecretServerSite class objects.
	
	By default, if no parameters are specified, this function will get all the Sites available in the connected
	Secret Server instance.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns SecretServerSite objects.

    .PARAMETER SiteName
    Get Secret Server Site by this site name.

	.PARAMETER SiteId
	Get Secret Server Site by this site Id.

	.EXAMPLE
    C:\PS> Get-SecretServerSite
	This function will get all Secret Server Sites from the connected Secret Server instance.

	.EXAMPLE
	C:\PS> Get-SecretServerSite -SiteName domain.com
	This function will get the Secret Server Site with the name "domain.com".

	.EXAMPLE
	C:\PS> Get-SecretServerSite -SiteId 4
	This function will get the Secret Server Site with the site id of 4.
	#>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Site to get.", ParameterSetName = "SiteName")]
		[System.String]$SiteName,

		[Parameter(Mandatory = $true, HelpMessage = "The ID of the Site to get.", ParameterSetName = "SiteId")]
		[System.Int32]$SiteId
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# making the query
	$basequery = Invoke-SecretServerAPI -APICall internals/sites?includeInactive=true

	# setting a new ArrayList for query results
	$queryresults = New-Object System.Collections.ArrayList

	# for each site found
	foreach ($query in $basequery)
	{
		$obj = New-Object SecretServerSite -ArgumentList ($query)

		$queryresults.Add($obj) | Out-Null
	}

	# return if a parameter set was used
	Switch ($PSCmdlet.ParameterSetName)
	{
		"SiteName"         
		{
			return $queryresults | Where-Object {$_.SiteName -eq $SiteName}
		}
		"SiteId"
		{
			return $queryresults | Where-Object {$_.SiteId -eq $SiteId}
		}
		default
		{
			return $queryresults
		}
	}# Switch ($PSCmdlet.ParameterSetName)
}# function global:Get-SecretServerSite
#endregion
###########