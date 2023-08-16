# class to hold a custom SSError
class SSAPIException : System.Exception
{
    [System.String]$APICall
    [System.String]$Payload
    [System.String]$ErrorMessage
    [PSCustomObject]$Response

    SSAPIException([System.String]$message) : base ($message) {}

    SSAPIException() {}
}# class SSAPIException : System.Exception