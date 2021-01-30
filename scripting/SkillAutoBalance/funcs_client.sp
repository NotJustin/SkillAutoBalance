void GetClientScore(int client)
{
	switch(g_ScoreType)
	{
		case ScoreType_gameME:
		{
			QueryGameMEStats("playerinfo", client, GameMEStatsCallback, 1);
		}
		case ScoreType_HLstatsX:
		{
			HLStatsX_Api_GetStats("playerinfo", client, HLStatsXStatsCallback, 0);
		}
		case ScoreType_KentoRankMe:
		{
			g_Players[client].score = float(RankMe_GetPoints(client));
		}
		case ScoreType_LevelsRanks:
		{
			g_Players[client].score = float(LR_GetClientInfo(client, ST_EXP));
		}
		case ScoreType_NCRPG:
		{
			g_Players[client].score = NCRPG_GetSkillSum(client);
		}
		case ScoreType_SABRating:
		{
			g_Players[client].score = SABRating_GetScore(client);
		}
		case ScoreType_SMRPG:
		{
			g_Players[client].score = float(SMRPG_GetClientLevel(client));
		}
	}
}

void PutClientOnATeam(int client)
{
	if (g_Players[client].team == CS_TEAM_SPECTATOR || g_Players[client].team == CS_TEAM_NONE)
	{
		SwapPlayer(client, GetSmallestTeam(), SAB_AutoJoin);
	}
	else if (CanJoin(client, g_Players[client].team))
	{
		SwapPlayer(client, g_Players[client].team, SAB_AutoJoin);
	}
	else if (g_Players[client].team == CS_TEAM_T)
	{
		SwapPlayer(client, CS_TEAM_CT, SAB_AutoJoin);
	}
	else
	{
		SwapPlayer(client, CS_TEAM_T, SAB_AutoJoin);
	}
}

void InitializeClient(int client)
{
	if (AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
	g_Players[client].team = CS_TEAM_SPECTATOR;
	g_Players[client].scoreUpdated = false;
	g_Players[client].score = -1.0;
	g_Players[client].isPassive = false;
	g_Players[client].isOutlier = false;
	++g_PlayerCountChange;
	bool teamMenuEnabled = cvar_TeamMenu.BoolValue;
	bool autoJoin = false;
	bool autoJoinSuccess = false;
	if ((cvar_ForceJoinTeam.IntValue == 1 && g_Players[client].forceJoinPreference == 1) || cvar_ForceJoinTeam.IntValue == 2 || (!cvar_ChatChangeTeam.BoolValue && !teamMenuEnabled && cvar_BlockTeamSwitch.BoolValue))
	{
		autoJoin = true;
		if (!AreTeamsFull())
		{
			autoJoinSuccess = true;
			g_Players[client].pendingForceJoin = true;
			int team = GetSmallestTeam();
			ClientCommand(client, "jointeam 0 %i", team);
			if (!IsPlayerAlive(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT) && (g_AllowSpawn || AreTeamsEmpty()))
			{
				CS_RespawnPlayer(client);
			}
		}
		else
		{
			ClientCommand(client, "spectate");
		}
	}
	else
	{
		g_Players[client].pendingForceJoin = false;
	}
	Call_StartForward(g_ClientInitializedForward);
	Call_PushCell(client);
	Call_PushCell(teamMenuEnabled);
	Call_PushCell(autoJoin);
	Call_PushCell(autoJoinSuccess);
	Call_Finish();
}
void PacifyPlayer(int client)
{
	Call_StartForward(g_PacifyForward);
	Call_PushCell(client);
	Call_Finish();
	g_Players[client].isPassive = true;
	SetEntityRenderColor(client, 0, 170, 174, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer((cvar_RoundRestartDelay.FloatValue - CHECKSCORE_DELAY), Timer_UnpacifyPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
void SwapPlayer(int client, int team, SABChangeTeamReason reason)
{
	Call_StartForward(g_SwapForward);
	Call_PushCell(client);
	Call_PushCell(team);
	Call_PushCell(reason);
	Call_Finish();
	if(team != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE)
	{
		if (IsPlayerAlive(client) && cvar_KeepPlayersAlive.BoolValue)
		{
			CS_SwitchTeam(client, team);
			CS_UpdateClientModel(client);
			PacifyPlayer(client);
			return;
		}
		ChangeClientTeam(client, team);
		return;
	}
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
}
SABJoinTeamResult CanJoin(int client, int team)
{
	int count[2];
	count[0] = GetTeamClientCount(CS_TEAM_T);
	count[1] = GetTeamClientCount(CS_TEAM_CT);
	int newTeamCount = count[team - 2];
	int otherTeamCount = count[(team + 1) % 2];
	int currentTeam = GetClientTeam(client);
	if (newTeamCount > otherTeamCount)
	{
		return SAB_NewTeamHasMorePlayers;
	}
	else if (newTeamCount == otherTeamCount && g_Players[client].team == team)
	{
		return SAB_JoinTeamSuccess;
	}
	else if (newTeamCount < otherTeamCount && currentTeam != CS_TEAM_T && currentTeam != CS_TEAM_CT)
	{
		return SAB_JoinTeamSuccess;
	}
	return SAB_MustJoinPreviousTeam;
}