# class to hold SecretServerConnections
class SecretServerConnection
{
    [System.String]$Url
    [PSCustomObject]$SecretServerConnection
    [System.Collections.Hashtable]$SecretServerSessionInformation

    SecretServerConnection($u,$ssc,$ss)
    {
        $this.Url = $u
        $this.SecretServerConnection = $ssc
        $this.SecretServerSessionInformation = $ss
    }
}# class SecretServerConnection