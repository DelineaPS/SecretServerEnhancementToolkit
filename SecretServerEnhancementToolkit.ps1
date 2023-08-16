#######################################
#region ### MAIN ######################
#######################################


# get every script inside the Classes folder
$classfolder = Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/DelineaPS/SecretServerEnhancementToolkit/tree/main/Classes'

# get every script inside the Functions folder
$functionfolder = Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/DelineaPS/SecretServerEnhancementToolkit/tree/main/Functions'

# parsing out the html for just the scripts in the classfolder (regex skipping any _*.ps1 scripts)
$ClassScripts = ($classfolder.RawContent -replace '\s','') | Select-String 'Classes\/(?!_)([a-zA-Z]+\-?[a-zA-Z]+\.ps1)' -AllMatches | foreach {$_.matches.Value -replace 'Classes\/(.*)','$1'} | Sort-Object -Unique
$ClassScripts | Add-Member -MemberType NoteProperty -Name "ScriptType" -Value "Class"
$ClassScripts | Add-Member -MemberType NoteProperty -Name FolderName -Value "Classes"

# parsing out the html for just the scripts in the classfolder (regex skipping any _*.ps1 scripts)
$FunctionScripts = ($functionfolder.RawContent -replace '\s','') | Select-String 'Functions\/(?!_)([a-zA-Z]+\-?[a-zA-Z]+\.ps1)' -AllMatches | foreach {$_.matches.Value -replace 'Functions\/(.*)','$1'} | Sort-Object -Unique
$FunctionScripts | Add-Member -MemberType NoteProperty -Name "ScriptType" -Value "Function"
$FunctionScripts | Add-Member -MemberType NoteProperty -Name FolderName -Value "Functions"

# ArrayList to put all our scripts into
$SecretServerEnhancementToolkitScripts = New-Object System.Collections.ArrayList
$SecretServerEnhancementToolkitScripts.AddRange(@($ClassScripts)) | Out-Null
$SecretServerEnhancementToolkitScripts.AddRange(@($FunctionScripts)) | Out-Null

# creating a ScriptBlock ArrayList
$SecretServerEnhancementToolkitScriptBlocks = New-Object System.Collections.ArrayList

# for each script found in $ClassScripts
foreach ($script in $SecretServerEnhancementToolkitScripts)
{
    # format the uri
    $uri = ("https://raw.githubusercontent.com/DelineaPS/SecretServerEnhancementToolkit/main/{0}/{1}" -f $script.FolderName, $script)

    # new temp object for the ScriptBlock ArrayList
    $obj = New-Object PSCustomObject

    # getting the scriptblock
    $scriptblock = ([ScriptBlock]::Create(((Invoke-WebRequest -Uri $uri).Content)))

    # setting properties
    $obj | Add-Member -MemberType NoteProperty -Name Name        -Value (($script.Split(".")[0]))
	$obj | Add-Member -MemberType NoteProperty -Name Type        -Value $script.ScriptType
    $obj | Add-Member -MemberType NoteProperty -Name Uri         -Value $uri
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