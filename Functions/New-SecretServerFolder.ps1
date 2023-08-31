###########
#region ### global:New-SecretServerFolder # Creates a new Secret Server Folder in the connected Secret Server instance.
###########
function global:New-SecretServerFolder
{
    <#
    .SYNOPSIS
    Creates a new Secret Server Folder.

    .DESCRIPTION
	This function creates a new Secret Server Folder in the connected Secret Server instance. By default this function
	will attempt to create a new Root level folder if just the name is specified.

	Otherwise, the Parent Folder can be specified as a string provided with the -ParentFolderPath parameter. A 
	SecretServerFolder class object is required for the SecretServerFolder parameter.

	This function returns a SecretServerFolder class object if successful. This function will return $false if a new
	folder was not created.

	.INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function returns a SecretServerFolder class object if it successfully creates a folder. Otherwise it will
	return $false if it does not.

    .PARAMETER Name
    The name of the Secret Server Folder to create.

	.PARAMETER ParentFolderPath
	The Folder Path name of the desired Parent Folder.

	.PARAMETER SecretServerFolder
	The SecretServerFolder class object to serve as the Parent Folder.

	.PARAMETER InheritPermissions
	Should permissions be inherited from the Parent Folder. Default is true.

	.PARAMETER InheritSecretPolicy
	Should Secret Policy be inherited from the Parent Folder. Default is true.

	.EXAMPLE
    C:\PS> New-SecretServerFolder -Name "My Team Folder"
    This function will create a new Root-level Secret Server Folder called "My Team Folder".

	.EXAMPLE
	C:\PS> New-SecretServerFolder -Name "WidgetApp Root Accounts" -ParentFolderPath "Apps\WidgetApp"
	This function will create a new Secret Server Folder in the "Apps\WidgetApps" directory named "WidgetApp Root Accounts."
	
	.EXAMPLE
	C:\PS> New-SecretServerFolder -Name "BlueCrab Accounts" -SecretServerFolder (Get-SecretServerFolder -Name "BlueCrabApp")
	This function will get the SecretServerFolder called "BlueCrabApp" and use that to serve as the Parent Folder for the 
	new "BlueCrab Accounts" subfolder.
    #>
    [CmdletBinding(DefaultParameterSetName="RootFolder")]
    param
    (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The name of the Folder to create.", ParameterSetName = "RootFolder")]
		[Parameter(Mandatory = $true, Position = 0, HelpMessage = "The name of the Folder to create.", ParameterSetName = "PathFolder")]
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "The name of the Folder to create.", ParameterSetName = "SecretServerFolder")]
		[System.String]$Name,

		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "The Folder Path of the Parent Folder.", ParameterSetName = "PathFolder")]
		[System.String]$ParentFolderPath,

		[Parameter(Mandatory = $true, Position = 1, HelpMessage = "The SecretServerFolder object to server as the Parent Folder.", ParameterSetName = "SecretServerFolder")]
		[PSTypeName('SecretServerFolder')]$SecretServerFolder,

		[Parameter(Mandatory = $false, HelpMessage = "Should permissions inherit from parent folder.", ParameterSetName = "PathFolder")]
		[Parameter(Mandatory = $false, HelpMessage = "Should permissions inherit from parent folder.", ParameterSetName = "SecretServerFolder")]
		[System.Boolean]$InheritPermissions = $true,

		[Parameter(Mandatory = $false, HelpMessage = "Should Secret policy inherit from parent folder.", ParameterSetName = "PathFolder")]
		[Parameter(Mandatory = $false, HelpMessage = "Should Secret policy inherit from parent folder.", ParameterSetName = "SecretServerFolder")]
		[System.Boolean]$InheritSecretPolicy = $true
    )

    # verifying an active CloudSuite connection
    Verify-SecretServerConnection

	# Body start
	$BodyPayload = @{}
	$BodyPayload.folderTypeId = 1

	# adding to the body payload based on our parameter set
	Switch ($PSCmdlet.ParameterSetName)
	{
		"RootFolder"
		{
			# preparing the body payload for a root folder creation
			$BodyPayload.folderName          = $Name
			$BodyPayload.parentFolderId      = -1
			$BodyPayload.inheritPermissions  = $false
			$BodyPayload.inheritSecretPolicy = $false
			break
		}# "RootFolder"
		"PathFolder"
		{
			Try
			{
				# try to get the folder by its specified FolderPath
				$Folder = Get-SecretServerFolder -FolderPath $ParentFolderPath

				# preparing the body payload for a root folder creation
				$BodyPayload.folderName          = $Name
				$BodyPayload.parentFolderId      = $Folder.ID
				$BodyPayload.inheritPermissions  = $InheritPermissions
				$BodyPayload.inheritSecretPolicy = $InheritSecretPolicy
				break
			}
			Catch
			{
				# we'll eventually refine this
				throw ("Something went wrong with PathFolder")
				$_
			}
		}# "PathFolder"
		"SecretServerFolder"
		{
			if (($SecretServerFolder | Measure-Object | Select-Object -ExpandProperty Count) -gt 1)
			{
				throw ("More than 1 Secret Server Folder provided. Please specify a single Secret Server Folder.")
			}

			Try
			{
				# preparing the body payload for a root folder creation
				$BodyPayload.folderName          = $Name
				$BodyPayload.parentFolderId      = $SecretServerFolder.ID
				$BodyPayload.inheritPermissions  = $InheritPermissions
				$BodyPayload.inheritSecretPolicy = $InheritSecretPolicy
				break
			}
			Catch
			{
				# we'll eventually refine this
				throw ("Something went wrong with SecretServerFolder")
				$_
			}
		}# "SecretServerFolder"
	}# Switch ($PSCmdlet.ParameterSetName)

	# make the call and attempt to create the folder
	if ($apicall = Invoke-SecretServerAPI -Method POST -APICall "api/v1/folders" -Body ($BodyPayload | ConvertTo-Json))
	{
		# if creation was successful, convert the data into a SecretServerFolder object
		$newfolder = ConvertFrom-DataToSecretServerFolder -DataFolders $apicall

		# and return it as a SecretServerFolder class object
		return $newfolder
	}
	else # otherwise
	{
		return $false
	}
}# function global:New-SecretServerFolder
#endregion
###########