# class to hold Secret Folders
class SecretServerFolder
{
	[System.Int32]$Id
	[System.String]$FolderName
	[System.String]$FolderPath
	[System.Int32]$ParentFolderId
	[System.Int32]$FolderTypeId
	[System.Int32]$SecretPolicyId
	[System.Boolean]$inheritSecretPolicy
	[System.Boolean]$inheritPermissions

	SecretServerFolder () {}

	SecretServerFolder ($f)
	{
		$this.Id                  = $f.Id
		$this.FolderName          = $f.FolderName
		$this.FolderPath          = $f.FolderPath
		$this.ParentFolderId      = $f.ParentFolderId
		$this.FolderTypeId        = $f.FolderTypeId
		$this.SecretPolicyId      = $f.SecretPolicyId
		$this.inheritSecretPolicy = $f.inheritSecretPolicy
		$this.inheritPermissions  = $f.inheritPermissions
	}# SecretServerFolder ($f)
}# class SecretServerFolder
