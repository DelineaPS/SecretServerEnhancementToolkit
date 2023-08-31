# class to hold Secret Templates
class SecretServerSecretTemplate
{
	[System.String]$Name
	[System.Int32]$Id

	SecretServerSecretTemplate () {}

	SecretServerSecretTemplate ($t)
	{
		$this.Name      = $t.name
		$this.Id        = $t.id
	}# SecretServerSecretTemplate ($p)
}# class SecretServerSecretTemplate
