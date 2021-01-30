public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("skillautobalance");
	g_LateLoad = late;
	return APLRes_Success;
}
public void OnClientPostAdminCheck(int client)
{
	if (AreTeamsFull())
	{
		bool admin = CheckCommandAccess(client, "", ADMFLAG_GENERIC, true);
		if (!admin)
		{
			CreateTimer(0.1, Timer_KickClient, GetClientUserId(client));
		}
		Call_StartForward(g_ClientKickForward);
		Call_PushCell(client);
		Call_PushCell(admin);
		Call_Finish();
	}
	g_Players[client].postAdminChecked = true;
	if (g_Players[client].fullyConnected)
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
		g_Players[client].forceJoinPreference = StringToInt(buffer);
	}
	else
	{
		g_Players[client].forceJoinPreference = 0;
	}
}
public void OnClientDisconnect(int client)
{
	g_Players[client].team = CS_TEAM_SPECTATOR;
	g_Players[client].scoreUpdated = false;
	g_Players[client].score = -1.0;
	g_Players[client].isPassive = false;
	g_Players[client].isOutlier = false;
	g_Players[client].forceJoinPreference = 0;
	g_Players[client].postAdminChecked = false;
	g_Players[client].fullyConnected = false;
	++g_PlayerCountChange;
	if (!AreTeamsEmpty())
	{
		return;
	}
	g_AllowSpawn = true;
}
public void OnConfigsExecuted()
{
	cvar_AutoTeamBalance.SetInt(0);
	cvar_LimitTeams.SetInt(0);
	UpdateConfigs();
}
public void OnMapEnd()
{
	g_MapLoaded = false;
}
public void OnMapStart()
{
	g_AllowSpawn = true;
	g_MapLoaded = true;
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
	if (g_Players[client].isPassive)
	{
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
public void OnPluginStart()
{
	CreateConVars();
	CreateForwards();
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
		for (int client = 1; client <= MaxClients; ++client)
		{
			if (IsClientInGame(client) && !IsClientSourceTV(client))
			{
				g_Players[client].team = GetClientTeam(client);
				if (AreClientCookiesCached(client))
				{
					OnClientCookiesCached(client);
				}
			}
		}	
	}
}