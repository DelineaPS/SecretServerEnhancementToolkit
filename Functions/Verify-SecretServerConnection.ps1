###########
#region ### Verify-SecretServerConnection # Check to ensure you are connected to the Secret Server instance.
###########
function global:Verify-SecretServerConnection
{
    <#
    .SYNOPSIS
    This function verifies you have an active connection to a Secret Server Instance.

    .DESCRIPTION
    This function verifies you have an active connection to a Secret Server Instance. It checks for the existance of a $SecretServerConnection 
    variable to first check if a connection has been made, then it makes a api/v1/version RestAPI call to ensure the connection is active and valid.
    This function will store a date any only check if the last attempt was made more than 5 minutes ago. If the last verify attempt occured
    less than 5 minutes ago, the check is skipped and a valid connection is assumed. This is done to prevent an overbundence of version calls to the 
    Secret Server Instance.

    .INPUTS
    None. You can't redirect or pipe input to this function.

    .OUTPUTS
    This function only throws an error if there is a problem with the connection.

    .EXAMPLE
    C:\PS> Verify-SecretServerConnection
    This function will not return anything if there is a valid connection. It will throw an exception if there is no connection, or an 
    expired connection.
    #>

    if ($SecretServerConnection -eq $null)
    {
        throw ("There is no existing `$SecretServerConnection. Please use Connect-SecretServerInstance to connect to your Secret Server Instance. Exiting.")
    }
    else
    {
        Try
        {
            # check to see if LastVersioncheck is available
            if ($global:LastVersioncheck)
            {
                # if it is, check to see if the current time is less than 5 minute from its previous version check
                if ($(Get-Date).AddMinutes(-5) -lt $global:LastVersioncheck)
                {
                    # if it has been less than 5 minutes, assume we're still connected
                    return
                }
            }# if ($global:LastVersioncheck)
            
            $uri = ("https://{0}/api/v1/version" -f $global:SecretServerConnection.Url)

            # calling api/v1/version
            $VersionResponse = Invoke-RestMethod -Method Get -Uri $uri @global:SecretServerSessionInformation
           
            # if the response was successful
            if ($VersionResponse.Success)
            {
                # setting the last version check to reduce frequent whoami calls
                $global:LastVersioncheck = (Get-Date)
                return
            }
            else
            {
                throw ("There is no active, valid Secret Server Instance connection. Please use Connect-SecretServerInstance to re-connect to your Secret Server instance. Exiting.")
            }
        }# Try
        Catch
        {
            throw ("There is no active, valid Secret Server Instance connection. Please use Connect-SecretServerInstance to re-connect to your Secret Server instance. Exiting.")
        }
    }# else
}# function global:Verify-SecretServerConnection
#endregion
###########