void GetScore(int client)
{
	g_iClientScore[client] = -1.0;
	int scoreType = cvar_ScoreType.IntValue;
	if (scoreType == TYPE_GAMEME)
	{
		if (g_UsingGameME)
		{
			QueryGameMEStats("playerinfo", client, GameMEStatsCallback, 1);
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("GameME not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_RANKME)
	{
		if (g_UsingRankME)
		{
			g_iClientScore[client] = float(RankMe_GetPoints(client));
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("kento_rankme not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_LVLRanks)
	{
		if (g_UsingLVLRanks)
		{
			g_iClientScore[client] = float(LR_GetClientInfo(client, ST_EXP));
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("LVL Ranks not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_NCRPG)
	{
		if (g_UsingNCRPG)
		{
			g_iClientScore[client] = NCRPG_GetSkillSum(client);
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("NCRPG not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_SMRPG)
	{
		if (g_UsingSMRPG)
		{
			g_iClientScore[client] = float(SMRPG_GetClientLevel(client));
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (scoreType == TYPE_HLSTATSX)
	{
		if (g_UsingHLStatsX)
		{
			HLStatsX_Api_GetStats("playerinfo", client, HLStatsXStatsCallback, 0);
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("HLStatsX not found. Use other score type");
		}
	}
	else
	{
		float kills, deaths;
		kills = float(GetClientFrags(client));
		deaths = float(GetClientDeaths(client));
		deaths = deaths < 1.0 ? 1.0 : deaths;
		if(scoreType == 0)
		{
			g_iClientScore[client] = kills / deaths;
		}
		else if(scoreType == 1)
		{
			g_iClientScore[client] = kills / deaths + kills / 10.0 - deaths / 20.0;
		}
		else if(scoreType == 2)
		{
			g_iClientScore[client] = kills * kills / deaths;
		}
		if (g_Balancing)
		{
			++g_PlayerCount;
			if (g_PlayerCount == GetClientCountMinusSourceTV())
			{
				BalanceSkill();
				g_PlayerCount = 0;
			}
		}
	}
}
void PacifyPlayer(int client)
{
	if(cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Pacified Client");
	}
	CS_UpdateClientModel(client);
	g_iClientFrozen[client] = true;
	SetEntityRenderColor(client, 0, 170, 174, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer(cvar_RoundRestartDelay.FloatValue, Timer_UnpacifyPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
void SwapPlayer(int client, int team, char reason[50])
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, reason);
	}
	g_iClientTeam[client] = team;
	if(team != TEAM_SPEC && team != UNASSIGNED)
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
	ChangeClientTeam(client, TEAM_SPEC);
}
bool CanJoin(int client, int team, bool printMessage)
{
	int count[2];
	count[0] = GetTeamClientCount(TEAM_T);
	count[1] = GetTeamClientCount(TEAM_CT);
	int newTeamCount = count[team - 2];
	int otherTeamCount = count[(team + 1) % 2];
	int currentTeam = GetClientTeam(client);
	if (newTeamCount > otherTeamCount)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Team Has More Players");
		}
		return false;
	}
	else if (newTeamCount == otherTeamCount && g_iClientTeam[client] == team)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Must Join Previous Team");
		}
		return true;
	}
	else if (newTeamCount < otherTeamCount && currentTeam != TEAM_T && currentTeam != TEAM_CT)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Must Join Previous Team");
		}
		return true;
	}
	return false;
}