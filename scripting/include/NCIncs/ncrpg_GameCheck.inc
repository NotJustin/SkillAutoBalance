#define GAMECSS GameCSS()
#define GAMECSGO GameCSGO()
#define GAMECSANY GameCSAny()

stock tValveGame;

stock ValveGameEnum NCRPG_GetGame() 
{
    return ValveGameEnum:tValveGame;
}

stock DetermineGameMode() 
{
    char gameDir[64];
    GetGameFolderName(gameDir, sizeof(gameDir));

    if (StrContains(gameDir, "cstrike", false) == 0) 
    {
        tValveGame = _:Game_CS;
        ServerCommand("sv_allowminmodels 0");
    } 
    else if(StrContains(gameDir, "csgo", false) == 0)
    {
        tValveGame = _:Game_CSGO;
    }
    else
    {
		NCRPg_LogPrint(LogType_FailState, "This game does not support New Concept Role Play Game");
    }
}

stock bool GameCSS() 
{
    return NCRPG_GetGame() == Game_CS;
}

stock bool GameCSGO() 
{
    return NCRPG_GetGame() == Game_CSGO;
}

stock bool GameCSAny() 
{
    ValveGameEnum Game = NCRPG_GetGame();
    return (Game == Game_CS || Game == Game_CSGO); 
}

stock bool CheckSMVersion(int version)
{
	static ConVar Version = null;
	if(Version == null)
	{
		Version = FindConVar("sourcemod_version");
	}
	char vers[24];
	Version.GetString(vers,sizeof vers);
	int i = StrContains(vers,"-",false);
	if(i!=-1) vers[i] = '\0'; 
	ReplaceString(vers,sizeof vers,".","",false);
	int sn = StringToInt(vers);
	if(sn<version) return false;
	else return true;
}