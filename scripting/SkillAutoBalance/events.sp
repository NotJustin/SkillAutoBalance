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
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (team == CS_TEAM_T || team == CS_TEAM_CT))
	{
		g_Players[client].team = team;
	}
}
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
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
	balanceReason = BalanceSkillNeeded();
	if(balanceReason != SAB_NoBalance)
	{
		SetStreak(event.GetInt("winner"));
		for (int client = 1; client <= MaxClients; ++client)
		{
			g_Players[client].scoreUpdated = false;
			g_Players[client].pendingSwap = false;
		}
		UpdateScores();
		CreateTimer(1.0, Timer_DelayBalance);
		g_fTeamWinStreak[0] = 0.0;
		g_fTeamWinStreak[1] = 0.0;
		g_PlayerCountChange = 0;
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
	g_Players[client].fullyConnected = true;
	if (g_Players[client].postAdminChecked)
	{
		InitializeClient(client);
	}
}