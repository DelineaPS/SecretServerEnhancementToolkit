###########
#region ### global:Invoke-SecretServerAPI # provides an easy way to interact with Secret Server's API endpoints
###########
function global:Invoke-SecretServerAPI
{
	<#
    .SYNOPSIS
    This function will provide an easy way to interact with any RestAPI endpoint in a Secret Server instance.

    .DESCRIPTION
    This function will provide an easy way to interact with any RestAPI endpoint in a Secret Server instance. 
	This function requires an existing, valid $SecretServerConnection to exist. 
	At a minimum, the APICall parameter is required. 

    .PARAMETER APICall
    Specify the RestAPI endpoint to target. For example "api/v1/healthcheck".

	.PARAMETER Method
	The method (GET/POST) to use for the call. Defaults to GET if not specified.

    .PARAMETER Body
    Specify the JSON body payload for the RestAPI endpoint if required.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function outputs as PSCustomObject with the requested data if the RestAPI call was successful.

    .EXAMPLE
    C:\PS> Invoke-SecretServerAPI -APICall api/v1/healthcheck
    This will attempt to reach the api/v1/healthcheck RestAPI endpoint to the currently connected Secret Server instance. 
	If there is a valid connection, basic health information will be returned.

    .EXAMPLE
    C:\PS> Invoke-SecretServerAPI -APICall api/v1/users/21
    Gets information about the user with the ID 21.
	
    #>
	param
    (
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Specify the API call to make.")]
        [System.String]$APICall,

		[Parameter(Position = 1, Mandatory = $false, HelpMessage = "Specify Invoke Method.")]
        [System.String]$Method = "GET",

        [Parameter(Position = 2, Mandatory = $false, HelpMessage = "Specify the JSON Body payload.")]
        [System.String]$Body
    )# param

	# setting the url based on our PlatformConnection information
    $uri = ("https://{0}/{1}" -f $global:SecretServerConnection.Url, $APICall)

	# Try
    Try
    {
        Write-Debug ("Uri=[{0}]" -f $uri)
        Write-Debug ("Body=[{0}]" -f $Body)

        # making the call using our a Splat version of our connection
        #$Response = Invoke-RestMethod -Method Get -Uri $uri -Body $Body @global:SecretServerSessionInformation
		# if -Body was used, include that
		if ($PSBoundParameters.ContainsKey('Body'))
		{
			$Response = Invoke-RestMethod -Uri $uri -Method $Method -Body $Body @global:SecretServerSessionInformation
		}
		else # don't include the Body parameter
		{
			$Response = Invoke-RestMethod -Uri $uri -Method $Method @global:SecretServerSessionInformation
		}
		
		return $Response
    }# Try
    Catch
    {
		$e = New-Object SecretServerException -ArgumentList ("A SecretServerAPI error has occured. Check `$LastError for more information")
        $e.AddAPIData($ApiCall, $Body, $response)
		$e.AddExceptionData($_)
        Write-Error $_.Exception.Message
		return $e
    }# Catch
}# function global:Invoke-SecretServerAPI
#endregion
###########