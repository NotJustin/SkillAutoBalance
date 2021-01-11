void UpdateBlockTeamSwitch(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_MapLoaded)
	{
		if (convar.IntValue == 2)
		{
			GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
		}
	}
}
void UpdateConfigs()
{
	char str[1];
	UpdateTeamMenu(cvar_TeamMenu, str, str);
	UpdateSetTeam(cvar_SetTeam, str, str);
	UpdateForceBalance(cvar_ForceBalance, str, str);
	UpdatePrefix(cvar_Prefix, str, str);
	UpdatePrefixColor(cvar_PrefixColor, str, str);
	UpdateMessageType(cvar_MessageType, str, str);
	UpdateBlockTeamSwitch(cvar_BlockTeamSwitch, str, str);
	UpdateAutoTeamBalance(cvar_AutoTeamBalance, str, str);
	UpdateLimitTeams(cvar_LimitTeams, str, str);
}
void UpdateAutoTeamBalance(ConVar convar, char [] oldValue, char [] newValue)
{
	convar.IntValue = 0;
}
void UpdateLimitTeams(ConVar convar, char [] oldValue, char [] newValue)
{
	convar.IntValue = 0;
}
void UpdateForceBalance(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_UsingAdminmenu && !g_ForceBalanceHooked && convar.BoolValue)
	{
		RegAdminCmd("sm_balance", Command_Balance, ADMFLAG_SLAY, "Forces a team balance to occur at the end of this round");
		TopMenu topmenu;
		if ((topmenu = GetAdminTopMenu()) != null)
		{
			OnAdminMenuReady(topmenu);
			AttachForceBalanceAdminMenu();
			g_ForceBalanceHooked = true;
		}
	}
}
void UpdateMessageColor(ConVar convar, char [] oldValue, char [] newValue)
{
	char sMessageColor[20];
	GetConVarString(convar, sMessageColor, sizeof(sMessageColor));
	int messageType = cvar_MessageType.IntValue;
	if (messageType == 0 || messageType == 1)
	{
		g_MessageColor = "\x01";
	}
	else if(messageType == 2 || messageType == 3)
	{
		SetColor(g_MessageColor, sMessageColor);
	}
}
void UpdateMessageType(ConVar convar, char [] oldValue, char [] newValue)
{
	char str[20];
	GetConVarString(cvar_MessageColor, str, sizeof(str));
	UpdateMessageColor(cvar_MessageColor, str, str);
	str[0] = '\0';
	GetConVarString(cvar_PrefixColor, str, sizeof(str));
	UpdatePrefixColor(cvar_PrefixColor, str, str);
}
void UpdatePrefix(ConVar convar, char [] oldValue, char [] newValue)
{
	GetConVarString(convar, g_Prefix, sizeof(g_Prefix));
}
void UpdatePrefixColor(ConVar convar, char [] oldValue, char [] newValue)
{
	char sPrefixColor[20];
	GetConVarString(convar, sPrefixColor, sizeof(sPrefixColor));
	int messageType = cvar_MessageType.IntValue;
	if (messageType == 0 || messageType == 2)
	{
		g_PrefixColor = "\x01";
	}
	else if(messageType == 1 || messageType == 3)
	{
		SetColor(g_PrefixColor, sPrefixColor);
	}
}
void UpdateSetTeam(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_UsingAdminmenu && !g_SetTeamHooked && convar.BoolValue)
	{
		RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_SLAY, "Set player to CT, T, or SPEC");
		TopMenu topmenu;
		if ((topmenu = GetAdminTopMenu()) != null)
		{
			OnAdminMenuReady(topmenu);
			AttachSetTeamAdminMenu();
			g_SetTeamHooked = true;
		}
	}
}
void UpdateTeamMenu(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_MapLoaded)
	{
		if (convar.BoolValue && cvar_BlockTeamSwitch.IntValue != 2)
		{
			GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
			return;
		}
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
	}
}