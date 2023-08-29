# class to hold Secret Permissions
class SecretServerPermission
{
	[System.Int32]$Id
	[System.Int32]$FolderId
	[System.Int32]$GroupId
	[System.String]$GroupName
	[System.Int32]$UserId
	[System.String]$UserName
	[System.Int32]$FolderAccessRoleId
	[System.String]$FolderAccessRoleName
	[System.Int32]$SecretAccessRoleId
	[System.String]$SecretAccessRoleName
	[System.String]$KnownAs
	[System.String]$DomainName

	SecretServerPermission () {}

	SecretServerPermission ($p)
	{
		$this.Id                   = $p.id
		$this.FolderId             = $p.folderId
		$this.GroupId              = $p.groupId
		$this.GroupName            = $p.groupName
		$this.UserId               = $p.userId
		$this.UserName             = $p.userName
		$this.FolderAccessRoleId   = $p.folderAccessRoleId
		$this.FolderAccessRoleName = $p.folderAccessRoleName
		$this.SecretAccessRoleId   = $p.secretAccessRoleId
		$this.SecretAccessRoleName = $p.secretAccessRoleName
		$this.KnownAs              = $p.knownAs
		$this.DomainName           = $p.domainName
	}# SecretServerPermission ($p)
}# class SecretServerPermission
