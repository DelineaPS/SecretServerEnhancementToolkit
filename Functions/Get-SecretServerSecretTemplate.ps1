###########
#region ### global:Get-SecretServerSecretTemplate # Gets Secret Server Secret Templates from the Secret Server instance
###########
function global:Get-SecretServerSecretTemplate
{
    <#
    .SYNOPSIS
    Gets Secret Server Secret Templates from the connected Secret Server instance.

    .DESCRIPTION
	This function will get Secret Server Secret Templates from the connected Secret Server instance, and process them into
	SecrerServerSecretTemplate class objects.
	
	By default, if no parameters are specified, this function will get up to 10000 Secret Server Secret Templates.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns SecrerServerSecretTemplate objects. It returns $false if there are no templates found.

    .PARAMETER Name
    Get Secret Server Secret Templates by this name. This is a 'like' search so any template that contains this string
	in the name will be returned.

	.PARAMETER Id
	Get Secret Server Secret Templates by this Id.

	.EXAMPLE
    C:\PS> Get-SecretServerSecretTemplate
	This function will get all the Secret Server Secret Templates from the connected Secret Server instance.

	.EXAMPLE
	C:\PS> Get-SecretServerSecretTemplate -Name "Web Password"
	This function will get the Secret Server Secret Template with the name "Web Password".

	.EXAMPLE
	C:\PS> Get-SecretServerSecretTemplate -Name "Password"
	This function will get any Secret Server Secret Templates with "Password" in the name.

	.EXAMPLE
	C:\PS> Get-SecretServerSecretTemplate -Id 6001
	This function will get the Secret Server Secret Template with Id of 6001.

	#>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Folder to search/get.", ParameterSetName = "Name")]
		[System.String]$Name,

		[Parameter(Mandatory = $true, HelpMessage = "The ID of the Folder to search/get.", ParameterSetName = "Id")]
		[System.Int32]$Id#,

		#[Parameter(Mandatory = $false, HelpMessage = "A raw filter to manually type in.", ParameterSetName = "RawFilter")]
		#[System.String]$RawFilter,

        #[Parameter(Mandatory = $false, HelpMessage = "Limits the number of results.")]
        #[System.Int32]$Limit = 10000
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# setting the base endpoint because v1 and v2 can differ depending on what we're getting
    [System.String]$endpoint = $null

	Switch ($PSCmdlet.ParameterSetName)
	{
		
		"Name"              { $endpoint = ("api/v1/secret-templates?filter.searchText={0}" -f $Name) ; break }
		"Id"                { $endpoint = ("api/v2/secret-templates/{0}" -f $Id) ; break }
		#"RawFilter"         { $filter = $RawFilter ; break }
		# All
		default             { $endpoint = "api/v1/secret-templates-list"; break }
	}# Switch ($PSCmdlet.ParameterSetName)

	#if ($PSCmdlet.ParameterSetName -ne "Id")
	#{
	#	$filter = ("{0}&take={1}" -f $filter, $Limit)
	#}

	Write-Verbose ("Endpoint: [{0}]" -f $endpoint)

	# making the query
    $basequery = Invoke-SecretServerAPI -APICall $endpoint

	# setting a new ArrayList for query results to deal with a childFolders property
	$queryresults = New-Object System.Collections.ArrayList

	# if the returned API call has the records property, more than one object was returned
	if ($basequery.records)
	{
		# but if its blank
		if (($basequery.records | Measure-Object | Select-Object -ExpandProperty Count) -eq 0)
		{
			return $false
		}
		$queryresults.AddRange(@($basequery.records)) | Out-Null
	}
	
	else
	{
		$queryresults.Add($basequery) | Out-Null
	}

	# multithread start
	$RunspacePool = [runspacefactory]::CreateRunspacePool(1,12)
	$RunspacePool.ApartmentState = 'STA'
	$RunspacePool.ThreadOptions = 'ReUseThread'
	$RunspacePool.Open()

	# processed ArrayList
	$processed = New-Object System.Collections.ArrayList

	# jobs ArrayList
	$Jobs = New-Object System.Collections.ArrayList

	# zeroing counters
	[System.Int32]$g, [System.Int32]$p = 0

	# for each CloudSuiteAccount passed
	foreach ($queryobject in $queryresults)
	{
		$PowerShell = [PowerShell]::Create()
		$PowerShell.RunspacePool = $RunspacePool
	
		# Counter for the account objects
		$g++; Write-Progress -Activity "Getting Secret Templates" -Status ("{0} out of {1} Complete" -f $g,$queryresults.Count) -PercentComplete ($g/($queryresults | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		# for each script in our SecretServerEnhancementToolkitScriptBlocks
		foreach ($script in $global:SecretServerEnhancementToolkitScriptBlocks)
		{
			# add it to this thread as a script, this makes all classes and functions available to this thread
			[void]$PowerShell.AddScript($script.ScriptBlock)
		}
		[void]$PowerShell.AddScript(
		{
			Param
			(
				$SecretServerConnection,
				$SecretServerSessionInformation,
				$queryobject
			)
			$global:SecretServerConnection                       = $SecretServerConnection
			$global:SecretServerSessionInformation               = $SecretServerSessionInformation

			$template = New-Object SecretServerSecretTemplate -ArgumentList ($queryobject)

			return $template
	
		})# [void]$PowerShell.AddScript(
		[void]$PowerShell.AddParameter('SecretServerConnection',$global:SecretServerConnection)
		[void]$PowerShell.AddParameter('SecretServerSessionInformation',$global:SecretServerSessionInformation)
		[void]$PowerShell.AddParameter('queryobject',$queryobject)
			
		$JobObject = @{}
		$JobObject.Runspace   = $PowerShell.BeginInvoke()
		$JobObject.PowerShell = $PowerShell
	
		$Jobs.Add($JobObject) | Out-Null
	}# foreach ($cloudsuiteaccount in $CloudSuiteAccounts)

	foreach ($job in $jobs)
	{
		# Counter for the job objects
		$p++; Write-Progress -Activity "Processing Secret Templates" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		$processed.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
		$job.PowerShell.Dispose()
	}# foreach ($job in $jobs)

	# closing the pool
	$RunspacePool.Close()
	$RunspacePool.Dispose()

	# converting back to SecrerServerSecretTemplate because multithreaded objects return an Automation object Type
	$secretserversecrettemplates = ConvertFrom-DataToSecretServerSecretTemplate -DataSecretTemplates $processed

	return $secretserversecrettemplates
}# function global:Get-SecretServerSecretTemplate
#endregion
###########