void HookEvents()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_connect_full", Event_PlayerConnectFull);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerTeam, EventHookMode_Pre);
}

void Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	if (cvar_EnablePlayerTeamMessage.BoolValue)
	{
		SetEventBroadcast(event, false);
	}
	else
	{
		SetEventBroadcast(event, true);
	}
}
void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_PlayerCount = 0;
	g_Balancing = false;
	bool warmupActive = IsWarmupActive();
	if (warmupActive)
	{
		g_AllowSpawn = true;
		return;
	}
	if (cvar_GraceTime.BoolValue)
	{
		g_AllowSpawn = true;
		CreateTimer(cvar_GraceTime.FloatValue, Timer_GraceTimeOver, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_AllowSpawn = false;
	++g_RoundCount;
	BalanceTeamCount();
	if(GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT) >= cvar_MinPlayers.IntValue)
	{
		SetStreak((GetEventInt(event, "winner") == TEAM_T) ? TEAM_T : TEAM_CT);
		if(g_ForceBalance || BalanceSkillNeeded())
		{
			g_Balancing = true;
			if (cvar_Scramble.BoolValue)
			{
				if (cvar_DisplayChatMessages.BoolValue)
				{
					ColorPrintToChatAll("Global Scramble Teams");
				}
				ScrambleTeams();
			}
			else
			{
				g_LastAverageScore = GetAverageScore();
				UpdateScores();
				g_iStreak[0] = 0.0;
				g_iStreak[1] = 0.0;
				g_PlayerCountChange = 0;
			}
		}
	}
	g_ForceBalance = false;
}
void Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast)
{
	int userId = event.GetInt("userid");
	int client = GetClientOfUserId(userId);
	if (!client|| !IsClientInGame(client))
	{
		return;
	}
	if (AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
	g_iClientTeam[client] = TEAM_SPEC;
	g_iClientScore[client] = -1.0;
	g_iClientFrozen[client] = false;
	g_iClientOutlier[client] = false;
	++g_PlayerCountChange;
	if (!cvar_TeamMenu.BoolValue && cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Team Menu Disabled");
	}
	if ((cvar_ForceJoinTeam.IntValue == 1 && g_iClientForceJoinPreference[client] == 1) || cvar_ForceJoinTeam.IntValue == 2 || (!cvar_ChatChangeTeam.BoolValue && !cvar_TeamMenu.BoolValue && cvar_BlockTeamSwitch.IntValue > 0))
	{
		g_iClientForceJoin[client] = true;
		int team = GetSmallestTeam();
		ClientCommand(client, "jointeam 0 %i", team);
		if (!IsPlayerAlive(client) && (g_iClientTeam[client] == TEAM_T || g_iClientTeam[client] == TEAM_CT) && (g_AllowSpawn || AreTeamsEmpty()))
		{
			CS_RespawnPlayer(client);
		}
	}
	else
	{
		ClientCommand(client, "spectate");
		g_iClientForceJoin[client] = false;
	}
}