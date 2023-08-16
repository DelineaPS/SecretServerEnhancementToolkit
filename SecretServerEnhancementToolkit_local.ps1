#######################################
#region ### MAIN ######################
#######################################

# get every script inside the Classes folder
$classfolder = Get-ChildItem -Path .\Classes\

# get every script inside the Functions folder
$functionfolder = Get-ChildItem -Path .\Functions\

# parsing out the html for just the scripts in the classfolder (regex skipping any _*.ps1 scripts)
$ClassScripts = $classfolder | Where-Object {$_.FullName -match '^.*Classes\\(?!_)([a-zA-Z]+\-?[a-zA-Z]+\.ps1)$'}
$ClassScripts | Add-Member -MemberType NoteProperty -Name "ScriptType" -Value "Class"

# parsing out the html for just the scripts in the classfolder (regex skipping any _*.ps1 scripts)
$FunctionScripts = $functionfolder | Where-Object {$_.FullName -match '^.*Functions\\(?!_)([a-zA-Z]+\-?[a-zA-Z]+\.ps1)$'}
$FunctionScripts | Add-Member -MemberType NoteProperty -Name "ScriptType" -Value "Function"

# ArrayList to put all our scripts into
$SecretServerEnhancementToolkitScripts = New-Object System.Collections.ArrayList
$SecretServerEnhancementToolkitScripts.AddRange(@($ClassScripts)) | Out-Null
$SecretServerEnhancementToolkitScripts.AddRange(@($FunctionScripts)) | Out-Null

# creating a ScriptBlock ArrayList
$SecretServerEnhancementToolkitScriptBlocks = New-Object System.Collections.ArrayList

# for each script found
foreach ($script in $SecretServerEnhancementToolkitScripts)
{
    # get the contents of the script
    $scriptcontents = Get-Content $script.FullName -Raw

    # new temp object for the ScriptBlock ArrayList
    $obj = New-Object PSCustomObject

    # getting the scriptblock
    $scriptblock = ([ScriptBlock]::Create(($scriptcontents)))

    # setting properties
    $obj | Add-Member -MemberType NoteProperty -Name Name        -Value $script.Name
	$obj | Add-Member -MemberType NoteProperty -Name Type        -Value $script.ScriptType
    $obj | Add-Member -MemberType NoteProperty -Name Path        -Value $script.FullName
    $obj | Add-Member -MemberType NoteProperty -Name ScriptBlock -Value $scriptblock

    # adding our temp object to our ArrayList
    $SecretServerEnhancementToolkitScriptBlocks.Add($obj) | Out-Null

    # and dot source it
    . $scriptblock
}# foreach ($script in $SecretServerEnhancementToolkitScripts)

# setting our ScriptBlock ArrayList to global
$global:SecretServerEnhancementToolkitScriptBlocks = $SecretServerEnhancementToolkitScriptBlocks

# initializing a List[SecretServerConnection] if it is empty or null
#$global:SecretServerConnections = New-Object System.Collections.Generic.List[SecretServerConnection]

#######################################
#endregion ############################
#######################################