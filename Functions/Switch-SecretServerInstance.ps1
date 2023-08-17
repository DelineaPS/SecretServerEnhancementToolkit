###########
#region ### global:Switch-SecretServerInstance # Changes the SecretServerConnection information to another connected tenant.
###########
function global:Switch-SecretServerInstance
{
    <#
    .SYNOPSIS
    This function will change the currently connected Secret Server instance to another connected Secret Server instance.

    .DESCRIPTION
	This function will change the current Secret Server connection information to another connected Secret Server connection.
	This function is only needed if you are working with two or more Secret Server instances. For example, if you are working on 
	mydev.secretservercloud.com and also on myprod.my.secretservercloud.com, this function can help you switch connections 
	between the two without having to reauthenticate to each one during the switch. Each connection must still initially be 
	completed once via the Connect-SecretServerInstance function.

    .PARAMETER Url
    Specify the tenant's URL to switch to. For example, mycompany.secretservercloud.com

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This script only returns $true on a successful switch, or $false if the specified Url was not found in the list of 
	connected Secret Server instances.

    .EXAMPLE
    C:\PS> Switch-SecretServerInstance -Url mycompany.secretservercloud.com
    This will switch your existing $SecretServerConnection and $SecretServerSessionInformation variables to the specified tenant. In this
    example, the login for mycopanyprod.my.centrify.net must have already been completed via the Connect-DelineaPlatform cmdlet.
    #>
    param
    (
		[Parameter(Position = 0, Mandatory = $true, HelpMessage = "The Url to switch to for authentication.")]
		[System.String]$Url
    )

    # if the $SecretServerConnections contains the Url in it's list
    if ($thisconnection = $global:SecretServerConnections | Where-Object {$_.Url -eq $Url})
    {
        # change the SecretServerConnection and SecretServerSessionInformation to the requested tenant
        $global:SecretServerSessionInformation = $thisconnection.SecretServerSessionInformation
        $global:SecretServerConnection = $thisconnection.SecretServerConnection
        return $true
    }# if ($thisconnection = $global:SecretServerConnections | Where-Object {$_.Url -eq $Url})
    else
    {
        return $false
    }
}# function global:Switch-SecretServerInstance
#endregion
###########
