###########
#region ### global:Connect-SecretServerInstance # Connects the user to a Secret Server instance.
###########
function global:Connect-SecretServerInstance
{
	<#
	.SYNOPSIS
    This cmdlet connects you to a Secret Server instance.

    .DESCRIPTION
    This cmdlet will connect you to a Secret Server instance. Information about your connection information will
    be stored in global variables that will only exist for this PowerShell session.

	.PARAMETER Url
    The url of the Secret Server instance to connect.

	.PARAMETER User
    The username to connect to the Secret Server instance.

    .INPUTS
    None.

    .OUTPUTS
    This cmdlet only outputs some information to the console window once connected. The cmdlet will store
    all relevant connection information in global variables that exist for this session only.

    .EXAMPLE
    C:\PS> Connect-SecretServerInstance -Url myinstance.secretservercloud.com -User myuser@domain.com
    This cmdlet will attempt to connect to myinstance.secretservercloud.com with the user myuser@domain.com.

    #>
    [CmdletBinding(DefaultParameterSetName="All")]
	param
	(
		[Parameter(Mandatory = $false, Position = 0, HelpMessage = "Specify the URL to use for the connection (e.g. myinstance.secretservercloud.com).")]
		[System.String]$Url,

		[Parameter(Mandatory = $true, HelpMessage = "Specify the User login to use for the connection (e.g. CloudAdmin@myinstance.secretservercloud.com).")]
		[System.String]$User
	)

	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

	# Debug preference
	if ($PSCmdlet.MyInvocation.BoundParameters["Debug"].IsPresent)
	{
		# Debug continue without waiting for confirmation
		$DebugPreference = "Continue"
	}
	else 
	{
		# Debug message are turned off
		$DebugPreference = "SilentlyContinue"
	}

	# Check if URL provided has "https://" in front, if so, remove it.
	if ($Url.ToLower().Substring(0,8) -eq "https://")
	{
		$Url = $Url.Substring(8)
	}

	$Uri = ("https://{0}/oauth2/token" -f $Url)
	Write-Host ("Connecting to Delinea Secret Server Instance (https://{0}) as {1}`n" -f $Url, $User)

	# Debug informations
	Write-Debug ("Uri= {0}" -f $Uri)
	Write-Debug ("User= {0}" -f $User)

	$SecureString = Read-Host -Prompt "Password" -AsSecureString

	$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))

	# setting the body
	$Body = @{}
	$Body.username = $User
	$Body.password = $Password
	$Body.grant_type = "password"

	# setting the header
	$Header = @{}
	$Header."Content-Type" = "application/x-www-form-urlencoded"

	Try
	{
		$InitialResponse = Invoke-WebRequest -UseBasicParsing -Method POST -SessionVariable SSSession -Uri $Uri -Body $Body -Headers $Header
	}
	Catch
	{
        $LastError = New-Object SSAPIException -ArgumentList ("A SecretServerAPI error has occured. Check `$LastError for more information")
		$LastError.APICall = $APICall
        $LastError.Payload = $Body
        $LastError.Response = $InitialResponse
        $LastError.ErrorMessage = $_.Exception.Message
        $global:LastError = $LastError
        Throw $_.Exception
	}

	# if the initial response was successful
	if ($InitialResponse.StatusCode -eq 200)
	{
		$accesstoken = $InitialResponse.Content | ConvertFrom-Json | Select-Object -ExpandProperty access_token

		$Connection = New-Object -TypeName PSCustomObject

		$Connection | Add-Member -MemberType NoteProperty -Name PodFqdn -Value $Url
		$Connection | Add-Member -MemberType NoteProperty -Name User -Value $User
		$Connection | Add-Member -MemberType NoteProperty -Name SessionStartTime -Value $InitialResponse.Headers.Date
		#$Connection | Add-Member -MemberType NoteProperty -Name Response -Value $InitialResponse

		# Set Connection as global
		$global:SecretServerConnection = $Connection

		# setting the bearer token header
		$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headers.Add("Authorization","Bearer $accesstoken")

		# setting the splat
		$global:SecretServerSessionInformation = @{ Headers = $headers; ContentType = "application/json" }

		return ($Connection | Select-Object User,PodFqdn | Format-List)
	}# if ($InitialResponse.StatusCode -eq 200)
	else
	{
		Write-Host ("Connection failed.")
		return $InitialResponse
	}

	return $InitialResponse
	
}# function global:Connect-SecretServerInstance
#endregion
###########