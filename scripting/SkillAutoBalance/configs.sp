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
	UpdateBlockTeamSwitch(cvar_BlockTeamSwitch, str, str);
	UpdateAutoTeamBalance(cvar_AutoTeamBalance, str, str);
	UpdateLimitTeams(cvar_LimitTeams, str, str);
	UpdateScoreType(cvar_ScoreType, str, str);
}
void UpdateAutoTeamBalance(ConVar convar, char[] oldValue, char[] newValue)
{
	convar.IntValue = 0;
}
void UpdateLimitTeams(ConVar convar, char[] oldValue, char[] newValue)
{
	convar.IntValue = 0;
}
void UpdateForceBalance(ConVar convar, char[] oldValue, char[] newValue)
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
void UpdateSetTeam(ConVar convar, char[] oldValue, char[] newValue)
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
void UpdateScoreType(ConVar convar, char[] oldValue, char[] newValue)
{
	SABScoreType scoreType = view_as<SABScoreType>(convar.IntValue);
	switch(scoreType)
	{
		case ScoreType_Auto:
		{
			scoreType = FindScoreType();
			if (scoreType != ScoreType_Invalid)
			{
				g_ScoreType = scoreType;
			}
			else
			{
				LogError("There are no scoretypes loaded on server.");
			}
		}
		case ScoreType_gameME:
		{
			OnLibraryAdded("gameme");
		}
		case ScoreType_HLstatsX:
		{
			OnLibraryAdded("hlstatsx_api");
		}
		case ScoreType_KentoRankMe:
		{
			OnLibraryAdded("kento_rankme");
		}
		case ScoreType_LevelsRanks:
		{
			OnLibraryAdded("levelsranks");
		}
		case ScoreType_NCRPG:
		{
			OnLibraryAdded("NCRPG");
		}
		case ScoreType_SABRating:
		{
			OnLibraryAdded("sab_rating");
		}
		case ScoreType_SMRPG:
		{
			OnLibraryAdded("smrpg");
		}
	}
}

void UpdateTeamMenu(ConVar convar, char[] oldValue, char[] newValue)
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