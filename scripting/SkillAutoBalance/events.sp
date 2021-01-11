void HookEvents()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_connect_full", Event_PlayerConnectFull);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerTeam, EventHookMode_Pre);
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (cvar_EnablePlayerTeamMessage.BoolValue)
	{
		SetEventBroadcast(event, false);
	}
	else
	{
		SetEventBroadcast(event, true);
	}
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	if (client && client < MaxClients && IsClientInGame(client) && (team == TEAM_T || team == TEAM_CT))
	{
		g_iClientTeam[client] = team;
	}
}
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (cvar_DisplayChatMessages.BoolValue && cvar_ChatChangeTeam.BoolValue)
	{
		PrintHowToJoinForSpectators();
	}
	g_PlayerCount = 0;
	g_Balancing = false;
	if (IsWarmupActive())
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
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_AllowSpawn = false;
	if (!IsWarmupActive())
	{
		++g_RoundCount;
	}
	if(GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT) >= cvar_MinPlayers.IntValue)
	{
		SetStreak(event.GetInt("winner"));
		if(BalanceSkillNeeded())
		{
			g_Balancing = true;
			int client;
			for (int i = 0; i < sizeof(g_iClient); i++)
			{
				client = g_iClient[i];
				g_bClientScoreUpdated[client] = false;
				g_bClientSwapPending[client] = false;
			}
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
				UpdateScores();
			}
			g_fTeamWinStreak[0] = 0.0;
			g_fTeamWinStreak[1] = 0.0;
			g_PlayerCountChange = 0;
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
	g_bClientConnectFull[client] = true;
	if (g_bClientPostAdminCheck[client])
	{
		InitializeClient(client);
	}
}