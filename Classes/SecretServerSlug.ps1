# class to hold Secret Server Slugs
class SecretServerSlug
{
	[System.String]$slug
	[System.String]$value

	SecretServerSlug () {}

	SecretServerSlug ($s)
	{
		$this.slug  = $s.slug
		$this.value = $s.value
	}# SecretServerSlug ($s)

	SecretServerSlug ($s, $v)
	{
		$this.slug  = $s
		$this.value = $v
	}# SecretServerSlug ($s, $v)
}# class SecretServerSlug