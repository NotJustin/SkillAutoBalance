stock void AddFolderDecalToDownloadsTable(const char[] sDirectory)
{
	char sFile[64]; char sPath[512];
	FileType iType; Handle hDir = OpenDirectory(sDirectory);
	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
			PrecacheDecal(sPath,true);
		}
	}
}

stock void AddFolderSoundToDownloadsTable(const char[] sDirectory)
{
	char sFile[64]; char sPath[512];
	Format(sPath, sizeof(sPath), "sound/%s", sDirectory);
	FileType iType; Handle hDir = OpenDirectory(sPath);

	while(ReadDirEntry(hDir, sFile, sizeof(sFile), iType))     
	{
		if(iType == FileType_File)
		{
			Format(sPath, sizeof(sPath), "sound/%s/%s", sDirectory, sFile);
			AddFileToDownloadsTable(sPath);
			Format(sPath, sizeof(sPath), "%s/%s", sDirectory,sFile);
			FakePrecacheSound(sPath);
		}
	}
}

stock void FakePrecacheSound(char[] szPath)
{
	char Path[80];
	Format(Path, sizeof(Path), "*%s", szPath);
	AddToStringTable(FindStringTable("soundprecache"), Path);
}