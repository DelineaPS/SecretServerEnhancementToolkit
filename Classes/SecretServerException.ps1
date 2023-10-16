# class to hold a custom SecretServerException
class SecretServerException
{
	[System.String]$Message
	[System.String]$ErrorMessage
	[System.DateTime]$ErroredOn
	[System.String]$FullyQualifiedErrorId
	[System.String]$Line
	[System.Int32]$LineNumber
	[System.Int32]$OffsetInLine
	[hashtable]$Data = @{}
	[PSCustomObject]$Exception
    [System.String]$APICall
    [System.String]$Payload
    [PSCustomObject]$Response

    SecretServerException([System.String]$m)
	{
		$this.Message = $m

		$this.ErroredOn = (Get-Date).ToString()

		$global:LastSecretServerError = $this
	}

	addExceptionData([PSCustomObject]$e)
	{
		$this.ErrorMessage          = $e.Exception.Message
		$this.FullyQualifiedErrorId = $e.FullyQualifiedErrorId
		$this.Line                  = $e.InvocationInfo.Line
		$this.LineNumber            = $e.InvocationInfo.ScriptLineNumber
		$this.OffsetInLine          = $e.InvocationInfo.OffsetInLine
		$this.Exception             = $e
	}# addExceptionData([PSCustomObject]$e)

	addAPIData([PSCustomObject]$a, [PSCustomObject]$b, [PSCustomObject]$r)
	{
		$this.APICall = $a
		$this.Payload = $b
		$this.Response = $r
	}

	addData($k,$v)
	{
		$this.Data.$k = $v
	}

	<#
	# how to use
	Catch
	{
		$e = New-Object SecretServerException -ArgumentList ("This errored here.")
		$e.AddAPIData($apicall, $payload, $response)
		$e.AddExceptionData($_)
		$e.AddData("variablename",$variable)
	}
	#>
}# SecretServerException