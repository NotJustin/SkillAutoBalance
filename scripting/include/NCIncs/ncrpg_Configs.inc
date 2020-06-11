
stock int GetConfigValue(KeyValues hConfig,const char[] section, const char[] key,int defvalue = 0,bool rewrite = true) {
	if(hConfig == INVALID_HANDLE)
		return 0;

	hConfig.Rewind();
	if(hConfig.JumpToKey(section,rewrite))
	{
		int newvalue = hConfig.GetNum(key, defvalue);
		if(rewrite) hConfig.SetNum(key,defvalue);
		hConfig.SetNum(key, newvalue);
		return newvalue;
	}
	return defvalue;
}

stock float GetConfigValueFloat(KeyValues hConfig,const char[] section, const char[] key, float defvalue = 0.0,bool rewrite = true) {
	if(hConfig == INVALID_HANDLE)
		return 0.0;

	hConfig.Rewind();
	if(hConfig.JumpToKey(section,rewrite))
	{
		float newvalue = hConfig.GetFloat(key, defvalue);
		if(rewrite) hConfig.SetFloat(key,defvalue);
		hConfig.SetFloat(key,newvalue);
		return newvalue;
	}
	return defvalue;
}

stock bool GetConfigValueString(KeyValues hConfig,const char[] section, const char[] key, char[] buffer,int maxlength, const char[] defvalue = "",bool rewrite = true) {
	if(hConfig == INVALID_HANDLE)
	{
		Format(buffer, maxlength, "ERROR");
		return false;
	}
	
	hConfig.Rewind();
	if(hConfig.JumpToKey(section,rewrite))
	{
		hConfig.GetString( key, buffer, maxlength, defvalue);
		if(rewrite) hConfig.SetString(key,defvalue);
		hConfig.SetString(key,buffer);
		return true;
	}
	strcopy(buffer, maxlength, defvalue);	
	return false;
}


stock KeyValues NCRPG_LoadConfigFile(char[] filename,char[] config_type = CONFIG_NULL,char[] config_format = CONFIG_TXT, bool create=true)
{
	KeyValues hConfig = new KeyValues("NCRPG");
	//KeyValues kv = CreateKeyValues("NCRPG");
	char full_path[512];
	FormatEx(full_path,sizeof full_path,"configs/NCRPG/%s%s%s",config_type,filename,config_format);
	BuildPath(Path_SM, full_path, sizeof full_path, full_path);
	if(!FileExists(full_path))
	{
		CloseHandle(CreateFile(full_path));
		hConfig.ExportToFile(full_path);
	}
	else hConfig.ImportFromFile(full_path);
	return hConfig;
}

stock void NCRPG_SaveConfigFile(KeyValues hConfig,char[] filename,char[] config_type = CONFIG_NULL,char[] config_format = CONFIG_TXT,close = true)
{
	char full_path[512];
	FormatEx(full_path,sizeof full_path,"configs/NCRPG/%s%s%s",config_type,filename,config_format);
	BuildPath(Path_SM, full_path, sizeof full_path, full_path);
	hConfig.GoBack();
	if(!FileExists(full_path))
	{
		CloseHandle(CreateFile(full_path));
		hConfig.ExportToFile(full_path);
	}
	hConfig.ExportToFile(full_path);
	if(close) delete hConfig;
}

stock File CreateFile(const char[] path, const char[] mode = "w+")
{
	char dir[12][PLATFORM_MAX_PATH]; char splitter[2] = "/"; 
	int count = FindCharInString(path, splitter[0], false);
	if(count==-1) splitter = "\\";
	count = ExplodeString(path, splitter, dir, 12, sizeof(dir[]));
	for(int i = 0; i < count-1; i++)
	{
		if(i > 0)
			Format(dir[i], sizeof(dir[]), "%s%s%s", dir[i-1],splitter, dir[i]);
			
		if(!DirExists(dir[i]))
			if(!CreateDirectory(dir[i], 511)) NCRPG_LogMessage(LogType_Error,"Не удалось создать путь %s",dir[i]);
	}
	
	return OpenFile(path, mode);
}


methodmap NCRPG_Configs
{
	public NCRPG_Configs(char[] filename,char[] config_type = CONFIG_NULL,char[] config_format = CONFIG_TXT, bool create=true)
	{
		return view_as<NCRPG_Configs>(NCRPG_LoadConfigFile(filename,config_type,config_format,create));
	}
	property KeyValues Kv
	{
		public get() { return view_as<KeyValues>(this); }
	}
	
	public int GetInt(const char[] section, const char[] key,int defvalue = 0,bool rewrite = true)
	{
		return GetConfigValue(this.Kv,section,key,defvalue,rewrite);
	}	
	public float GetFloat(const char[] section, const char[] key,float defvalue = 0.0,bool rewrite = true)
	{
		return GetConfigValueFloat(this.Kv,section,key,defvalue,rewrite);
	}	
	public bool GetString(const char[] section, const char[] key,char[] buffer,int maxlength, const char[] defvalue = "",bool rewrite = true)
	{
		return GetConfigValueString(this.Kv,section,key,buffer,maxlength,defvalue,rewrite);
	}
	public void SaveConfigFile(char[] filename,char[] config_type = CONFIG_NULL,char[] config_format = CONFIG_TXT,bool close = true)
	{
		if(this.Kv!=null && this.Kv!=INVALID_HANDLE) NCRPG_SaveConfigFile(this.Kv,filename,config_type,config_format,close);
	}
};
