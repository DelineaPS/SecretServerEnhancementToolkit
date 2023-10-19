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

	.PARAMETER FolderPath
	Gets a Secret Server Folder by explicit folder path.

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
	C:PS> Get-SecretServerFolder -FolderPath "Personal Folders\My RootFolder"
	This function will get the folder called "My RootFolder" from your Personal Folders".

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

		[Parameter(Mandatory = $true, HelpMessage = "The Folder Path of the Folder to search/get.", ParameterSetName = "FolderPath")]
		[System.String]$FolderPath,
		
		[Parameter(Mandatory = $false, HelpMessage = "Include subfolders from the ID search.", ParameterSetName = "Id")]
		[Parameter(Mandatory = $false, HelpMessage = "The ID of the Folder to search/get.", ParameterSetName = "FolderPath")]
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
									$filter = ("{0}?getAllChildren=true" -f $filter)
								}
								break
							}
		"FolderPath"        { 
								# replace forward slashs with backslashes
								$FolderPath = $FolderPath -replace '/','\'

								# if the first character is not a backslash, add a backslash at the beginning of the string
								if ($FolderPath[0] -ne "\") { $FolderPath = ("\{0}" -f $FolderPath) }
								$filter = ("/0?folderPath={0}" -f $FolderPath)
								if ($IncludeSubFolders.IsPresent)
								{
									$filter = ("{0}&getAllChildren=true" -f $filter)
								}

								# if the FolderPath ends in a backslash, truncate it
								if ($filter[-1] -eq "\") { $filter = $filter.Substring(0,$filter.Length - 1) }
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

	# setting a new ArrayList for query results to deal with a childFolders property
	$queryresults = New-Object System.Collections.ArrayList

	# if the returned API call has the records property, more than one object was returned
	if ($basequery.records)
	{
		$queryresults.AddRange(@($basequery.records)) | Out-Null
	}
	# else if the childFolders property exists, then the child folders were returned
	elseif ($basequery.childFolders)
	{
		$queryresults.Add(($basequery | Select-Object -Property * -ExcludeProperty childFolders)) | Out-Null
		$queryresults.AddRange(@($basequery.childFolders)) | Out-Null
	}
	else
	{
		$queryresults.Add($basequery) | Out-Null
	}

	Write-Verbose ("basesqlquery objects [{0}]" -f $queryresults.Count)

	# if $queryresults has more than 0 results
	if (($queryresults | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
	{
		# multithread start
		$RunspacePool = [runspacefactory]::CreateRunspacePool(1,12)
		$RunspacePool.ApartmentState = 'STA'
		$RunspacePool.ThreadOptions = 'ReUseThread'
		$RunspacePool.Open()

		# synchronized arraylists to hold our error and account stacks
		$errorstack = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
		$folderstack = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    
		# jobs ArrayList
		$Jobs = New-Object System.Collections.ArrayList

		# processed ArrayList
		$processed = New-Object System.Collections.ArrayList

		# zeroing counters
		[System.Int32]$g, [System.Int32]$p = 0

		# for each query object passed
		foreach ($queryobject in $queryresults)
		{
			$PowerShell = [PowerShell]::Create()
			$PowerShell.RunspacePool = $RunspacePool
		
			# Counter for the account objects
			$g++; Write-Progress -Activity "Getting Folders" -Status ("{0} out of {1} Complete" -f $g,$queryresults.Count) -PercentComplete ($g/($queryresults | Measure-Object | Select-Object -ExpandProperty Count)*100)
			
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
					$queryobject,
					$errorstack,
					$folderstack
				)
				$global:SecretServerConnection                       = $SecretServerConnection
				$global:SecretServerSessionInformation               = $SecretServerSessionInformation

				Try
				{
					# create a new Secret Server Folder object
					$folder = New-Object SecretServerFolder -ArgumentList ($queryobject)
					$folderpermissions = Get-SecretServerFolderPermission -Id $folder.Id
					$folder.addFolderPermission($folderpermissions)
					$folderstack.add($folder) | Out-Null
				}# Try
				Catch
				{
					# if an error occurred during New-Object, create a new SecretServerException and return that with the relevant data
					$e = New-Object SecretServerException -ArgumentList ("Error during New SecretServerFolder object.")
					$e.AddExceptionData($_)
					$e.AddData("queryobject",$queryobject)
					$errorstack.Add($e) | Out-Null
				}# Catch
			})# [void]$PowerShell.AddScript(
			[void]$PowerShell.AddParameter('SecretServerConnection',$global:SecretServerConnection)
			[void]$PowerShell.AddParameter('SecretServerSessionInformation',$global:SecretServerSessionInformation)
			[void]$PowerShell.AddParameter('queryobject',$queryobject)
			[void]$PowerShell.AddParameter('errorstack',$errorstack)
			[void]$PowerShell.AddParameter('folderstack',$folderstack)
				
			$JobObject = @{}
			$JobObject.Runspace   = $PowerShell.BeginInvoke()
			$JobObject.PowerShell = $PowerShell
		
			$Jobs.Add($JobObject) | Out-Null
		}# foreach ($queryobject in $queryresults)

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
	}# if (($queryresults | Measure-Object | Select-Object -ExpandProperty Count) -gt 0)
	else
    {
        return $false
    }

	# setting all the errored into the LastErrorStack
	$global:LastErrorStack = $errorstack

	return $folderstack
}# function global:Get-SecretServerFolder
#endregion
###########