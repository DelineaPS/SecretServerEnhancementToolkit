###########
#region ### global:Get-SecretServerFolder # Gets Secret Server Folders from the Secret Server instance
###########
function global:Get-SecretServerFolder
{
    <#
    .SYNOPSIS
    Gets Secret Server Folders from the connected Secret Server instance.

    .DESCRIPTION
	This function will get Secret Server Folders from the connected Secret Server instance, and process them into
	SecretServerFolder class objects.
	
	By default, if no parameters are specified, this function will get up to 10000 Secret Server Folders.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns SecretServerFolder objects.

    .PARAMETER Name
    Get Secret Server Folders by this name.

	.PARAMETER Id
	Get Secret Server Folders by this Id.

	.PARAMETER IncludeSubFolders
	Get all Secret Server Folders under the specified folder. Only works with the -Id parameter.

	.PARAMETER ParentFolderId
	Gets all Secret Server Folders under the specified folder ID.

	.PARAMETER RawFilter
	Specify a filter string manually, this string will be appended to "/api/v1/folders". In most cases, this would also need
	to include the leading "?" to append to the end of the url.

	.PARAMETER Limit
	Limits the number of folders to return. Default is 10,000.

	.EXAMPLE
    C:\PS> Get-SecretServerFolder
	This function will get up to 10,000 folders from the connected Secret Server instance.

	.EXAMPLE
	C:\PS> Get-SecretServerFolder -Name MyFolder
	This function will get all folders named "MyFolder"

	.EXAMPLE
	C:\PS> Get-SecretServerFolder -Id 4
	This function will get the folder with the Id of 4.

	.EXAMPLE
	C:\PS> Get-SecretServerFolder -Id 4 -IncludeSubFolders
	This function will get the folder with the Id of 4, including subfolders.

	.EXAMPLE
	C:\PS> Get-SecretServerFolder -ParentFolderId 1
	This function will get all the folders under the Folder that has the FolderID of 1.

	.EXAMPLE
	C:\PS> Get-SecretServerFolder -RawFilter "?filter.searchText=Root Accounts&skip=3&take=1"
	This function will get all folders named "Root Accounts", but skipping the first 3 results and only returning 1.
    #>
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(Mandatory = $true, HelpMessage = "The name of the Folder to search/get.", ParameterSetName = "Name")]
		[System.String]$Name,

		[Parameter(Mandatory = $true, HelpMessage = "The ID of the Folder to search/get.", ParameterSetName = "Id")]
		[System.Int32]$Id,
		
		[Parameter(Mandatory = $false, HelpMessage = "Include subfolders from the ID search.", ParameterSetName = "Id")]
		[Switch]$IncludeSubFolders,

		[Parameter(Mandatory = $true, HelpMessage = "Search for this folder by ID, and only return sub folders.", ParameterSetName ="ParentFolderId")]
		[System.String]$ParentFolderId,

		[Parameter(Mandatory = $false, HelpMessage = "A raw filter to manually type in.", ParameterSetName = "RawFilter")]
		[System.String]$RawFilter,

        [Parameter(Mandatory = $false, HelpMessage = "Limits the number of results.")]
        [System.Int32]$Limit = 10000
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# setting the base filter
    [System.String]$filter = $null

	Switch ($PSCmdlet.ParameterSetName)
	{
		"RawFilter"         { $filter = $RawFilter ; break }
		"Name"              { $filter = ("?filter.searchText={0}" -f $Name) ; break }
		"ParentFolderId"    { $filter = ("?filter.parentFolderId={0}" -f $ParentFolderId) ; break }
		"Id"                { 
								$filter = ("/{0}" -f $Id)
								if ($IncludeSubFolders.IsPresent)
								{
									$filter = ("{0}&getAllChildren=true" -f $filter)
								}
								break
							}
		default             { $filter = "?"; break }
	}# Switch ($PSCmdlet.ParameterSetName)

	if ($PSCmdlet.ParameterSetName -ne "Id")
	{
		$filter = ("{0}&take={1}" -f $filter, $Limit)
	}

	Write-Verbose ("Filter: [{0}]" -f $filter)

	# making the query
    $basequery = Invoke-SecretServerAPI -APICall ("api/v1/folders{0}" -f $filter)

	# if the returned API call has the records property, more than one object was returned
	if ($basequery.records)
	{
		# set that as our new base objects
		$basequery = $basequery.records
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
	foreach ($queryobject in $basequery)
	{
		$PowerShell = [PowerShell]::Create()
		$PowerShell.RunspacePool = $RunspacePool
	
		# Counter for the account objects
		$g++; Write-Progress -Activity "Getting Folders" -Status ("{0} out of {1} Complete" -f $g,$basequery.Count) -PercentComplete ($g/($basequery | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
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

			$folder = New-Object SecretServerFolder -ArgumentList ($queryobject)

			$folderpermissions = Get-SecretServerFolderPermission -Id $folder.Id

			$folder.addFolderPermission($folderpermissions)

			return $folder
	
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
		$p++; Write-Progress -Activity "Processing Folders" -Status ("{0} out of {1} Complete" -f $p,$jobs.Count) -PercentComplete ($p/($jobs | Measure-Object | Select-Object -ExpandProperty Count)*100)
		
		$processed.Add($job.powershell.EndInvoke($job.RunSpace)) | Out-Null
		$job.PowerShell.Dispose()
	}# foreach ($job in $jobs)

	# closing the pool
	$RunspacePool.Close()
	$RunspacePool.Dispose()

	# converting back to SecretServerFolder because multithreaded objects return an Automation object Type
	$secretserverfolders = ConvertFrom-DataToSecretServerFolder -DataFolders $processed

	return $secretserverfolders
}# function global:Get-SecretServerFolder
#endregion
###########