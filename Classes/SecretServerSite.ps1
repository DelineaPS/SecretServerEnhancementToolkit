# class to hold Secret Server Sites
class SecretServerSite
{
	[System.String]$SiteName
	[System.Int32]$SiteId
	[System.Boolean]$Active

	SecretServerSite () {}

	SecretServerSite ($s)
	{
		$this.SiteName = $s.SiteName
		$this.SiteId   = $s.SiteId
		$this.Active   = $s.Active
	}# SecretServerSite ($s)
}# class SecretServerSite
