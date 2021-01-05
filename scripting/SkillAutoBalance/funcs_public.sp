public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_LateLoad = late;
	return APLRes_Success;
}
public void OnClientPostAdminCheck(int client)
{
	if (AreTeamsFull())
	{
		if (!CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
		{
			CreateTimer(0.1, Timer_KickClient, GetClientUserId(client));
		}
		else
		{
			ColorPrintToChat(client, "Not Kicked Because Admin");
		}
	}
	g_bClientPostAdminCheck[client] = true;
	if (g_bClientConnectFull[client])
	{
		InitializeClient(client);
	}
}
public void OnClientCookiesCached(int client)
{
	char buffer[24];
	GetClientCookie(client, g_hForceSpawn, buffer, sizeof(buffer));
	if (strlen(buffer) > 0)
	{
		g_iClientForceJoinPreference[client] = StringToInt(buffer);
	}
	else
	{
		g_iClientForceJoinPreference[client] = 0;
	}
}
public void OnClientDisconnect(int client)
{
	g_iClientTeam[client] = TEAM_SPEC;
	g_bClientScoreUpdated[client] = false;
	g_fClientScore[client] = -1.0;
	g_bClientIsFrozen[client] = false;
	g_bClientIsOutlier[client] = false;
	g_iClientForceJoinPreference[client] = 0;
	g_bClientPostAdminCheck[client] = false;
	g_bClientConnectFull[client] = false;
	++g_PlayerCountChange;
	if (!AreTeamsEmpty())
	{
		return;
	}
	g_AllowSpawn = true;
}
public void OnConfigsExecuted()
{
	UpdateConfigs();
	CheckIfLibrariesExist();
}
public void OnMapEnd()
{
	g_MapLoaded = false;
}
public void OnMapStart()
{
	g_AllowSpawn = true;
	g_MapLoaded = true;
	g_PlayerCount = 0;
	g_PlayerCountChange = 0;
	g_RoundCount = 0;
	if (cvar_TeamMenu.BoolValue)
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
	}
	else
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
	}
	g_fTeamWinStreak[0] = 0.0;
	g_fTeamWinStreak[1] = 0.0;
}
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (g_bClientIsFrozen[client])
	{
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public void OnPluginStart()
{
	InitColorStringMap();
	CreateConVars();
	AddChangeHooks();
	HookEvents();
	RegCommands();

	AddCommandListener(CommandList_JoinTeam, "jointeam");
	AddCommandListener(CommandList_JoinTeam, "spectate");

	AutoExecConfig(true, "SkillAutoBalance");

	LoadTranslations("skillautobalance.phrases");
	LoadTranslations("common.phrases");

	CreateForceJoinCookie();

	if (g_LateLoad)
	{
		OnConfigsExecuted();
		for (int i = 0; i < MaxClients; ++i)
		{
			if (IsClientInGame(g_iClient[i]))
			{
				g_iClientTeam[i] = GetClientTeam(g_iClient[i]);
			}
		}	
	}
}