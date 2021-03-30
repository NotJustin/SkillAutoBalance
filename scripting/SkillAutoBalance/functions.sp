// If a server has a GOTV bot, we want to exclude it from GetClientCount
// when getting the average scores in GetAverageScore.
int GetClientCountMinusSourceTV()
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && IsClientSourceTV(client))
		{
			return GetClientCount(true) - 1;
		}
	}
	return GetClientCount(true);
}

// If the scoretype is manually set in the config, check if it exists.
void DoesScoreTypeExist(const char[] name, SABScoreType scoreType)
{
	// Set the scoretype to be the new one regardless.
	// If the scoretype isn't loaded, it shouldn't be this plugin's fault.
	g_ScoreType = scoreType;
	if (!LibraryExists(name))
	{
		LogError("Attempting to use score from plugin %s, but it is not loaded", name);
	}
}

// If for some reason we fail to update some client(s) scores,
// we get the average of all of the other client scores.
float GetAverageScore()
{
	int count = GetClientCountMinusSourceTV();
	float sum = 0.0;
	int missingScores = 0;
	int client = 0;
	int counted = 0;
	while(counted < count)
	{
		++client;
		if (client > MaxClients)
		{
			break;
		}
		if (!IsClientInGame(client) || IsClientSourceTV(client))
		{
			continue;
		}
		++counted;
		if (g_ClientData[client].score != -1.0)
		{
			sum += g_ClientData[client].score;
		}
		else
		{
			++missingScores;
		}
	}
	return sum / (count - missingScores);
}

void BalanceSkill()
{
	ArrayList sortedPlayers = new ArrayList();
	InitSortedArray(sortedPlayers);
	
	Call_StartForward(g_BalanceForward);
	Call_PushCellRef(sortedPlayers); // Do not delete the arraylist :D
	Call_PushString(g_sBalanceReason);
	Call_Finish();
	
	if (sortedPlayers == null)
	{
		LogError("The sortedPlayers arraylist was deleted by another plugin, when it should not have been.");
		return;
	}
	sortedPlayers.Clear();
	delete sortedPlayers;
}

// Create an arraylist, push all players in it who are on either terrorist or counter terrorist.
void InitSortedArray(ArrayList &sortedPlayers)
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		int team;
		if (IsClientInGame(client) && !IsClientSourceTV(client) && (team = GetClientTeam(client)) != CS_TEAM_NONE && team != CS_TEAM_SPECTATOR)
		{
			sortedPlayers.Push(client);
		}
	}
	// Sort the array in descending order of the client scores.
	SortADTArrayCustom(sortedPlayers, Sort_Scores);
}

int Sort_Scores(int index1, int index2, Handle array, Handle hndl)
{
	int client1 = view_as<ArrayList>(array).Get(index1);
	int client2 = view_as<ArrayList>(array).Get(index2);
	// If the server has bots and we don't count them as players,
	// move the bots to the end of the list.
	if (!cvar_BotsArePlayers.BoolValue)
	{
		if (!IsFakeClient(client1) && IsFakeClient(client2))
		{
			return -1;
		}
		if (IsFakeClient(client1) && !IsFakeClient(client2))
		{
			return 1;
		}
		if (IsFakeClient(client1) && IsFakeClient(client2))
		{
			return 0;
		}
	}
	if(g_ClientData[client1].score == g_ClientData[client2].score)
	{
		return 0;
	}
	return g_ClientData[client1].score > g_ClientData[client2].score ? -1 : 1;
}

void UpdateScores()
{
	if (g_ScoreType == ScoreType_Invalid)
	{
		LogError("No scoretype currently loaded. Cannot update client scores.");
		return;
	}
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && !IsClientSourceTV(client))
		{
			GetClientScore(client);
		}
	}
}

// For every client whose score failed to update, set their score to the average.
void FixMissingScores()
{
	g_LastAverageScore = GetAverageScore();
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client) || IsClientSourceTV(client))
		{
			continue;
		}
		// The only time a client's score can be -1.0 is if their score has never been updated,
		// or specifically if gameme is being used and it failed for some reason.
		if (g_ClientData[client].score == -1.0)
		{
			g_ClientData[client].score = g_LastAverageScore;
		}
	}
}

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
			g_ClientData[client].score = float(RankMe_GetPoints(client));
		}
		case ScoreType_LevelsRanks:
		{
			g_ClientData[client].score = float(LR_GetClientInfo(client, ST_EXP));
		}
		case ScoreType_NCRPG:
		{
			g_ClientData[client].score = NCRPG_GetSkillSum(client);
		}
		case ScoreType_KPRRating:
		{
			g_ClientData[client].score = KPRRating_GetScore(client);
		}
		case ScoreType_SMRPG:
		{
			g_ClientData[client].score = float(SMRPG_GetClientLevel(client));
		}
	}
}

// When we change a player's team while they are alive,
// if sab_keepplayersalive is enabled we will make the player passive at round_end.
// This means, they are given god and aren't able to attack until the next round.
void PacifyPlayer(int client)
{
	Call_StartForward(g_PacifyForward);
	Call_PushCell(client);
	Call_Finish();
	g_ClientData[client].isPassive = true;
	SetEntityRenderColor(client, 0, 170, 174, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer((cvar_RoundRestartDelay.FloatValue - CHECKSCORE_DELAY), Timer_UnpacifyPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

void SwapPlayer(int client, int team, char reason[50])
{
	Call_StartForward(g_SwapForward);
	Call_PushCell(client);
	Call_PushCell(team);
	Call_PushString(reason);
	Call_Finish();
	team == CS_TEAM_SPECTATOR || team == CS_TEAM_NONE ? MoveToSpec(client) : MoveToTeam(client, team, reason);
}

void MoveToSpec(int client)
{
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	ChangeClientTeam(client, CS_TEAM_SPECTATOR); //Not moving players to unassigned team.
}

void MoveToTeam(int client, int team, char reason[50])
{
	if (!IsPlayerAlive(client) || !cvar_KeepPlayersAlive.BoolValue)
	{
		ChangeClientTeam(client, team);
		return;
	}
	CS_SwitchTeam(client, team);
	CS_UpdateClientModel(client);
	/**
	 * We make clients "passive" when their team is changed by skill balance.
	 * This is to avoid the situation where the client can fight their former
	 * teammates after skill balance occurs.
	 *
	 * The situation that skips over this conditional is
	 * when an admin changes a player's team. This can occur at any point
	 * during a round, and making a player "passive" mid-round is not ideal.
	 */
	if (strcmp(reason, "Client Skill Balance", true) == 0)
	{
		PacifyPlayer(client);
	}
}

Action Timer_UnpacifyPlayer(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);
	g_ClientData[client].isPassive = false;
	if(client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	SetEntityRenderColor(client, 255, 255, 255, 255);
	/*
	 * delaying god removal to prevent players from being killed in last frame.
	 * I worry this makes them immortal very briefly on round start.
	 * However, I don't think it is normal for players to die immediately when they spawn anyway.
	 * Also. I'm wondering if instead of RequestFrame, this should be a timer of 0.1?
	**/
	RequestFrame(RemoveGod, userID);
	return Plugin_Handled;
}

void RemoveGod(int userID)
{
	int client = GetClientOfUserId(userID);
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}

Action Timer_DelayBalance(Handle timer)
{
	if (!g_bBalanceNeeded)
	{
		return;
	}
	// Set balance to false if we are about to balance teams.
	g_bBalanceNeeded = false;
	FixMissingScores();
	BalanceSkill();
}

SABScoreType FindScoreType()
{
	if (LibraryExists("gameme"))
	{
		return ScoreType_gameME;
	}
	else if (LibraryExists("hlstatsx_api"))
	{
		return ScoreType_HLstatsX;
	}
	else if (LibraryExists("kento_rankme"))
	{
		return ScoreType_KentoRankMe;
	}
	else if (LibraryExists("levelsranks"))
	{
		return ScoreType_LevelsRanks;
	}
	else if (LibraryExists("NCRPG"))
	{
		return ScoreType_NCRPG;
	}
	else if (LibraryExists("kpr_rating"))
	{
		return ScoreType_KPRRating;
	}
	else if (LibraryExists("smrpg"))
	{
		return ScoreType_SMRPG;
	}
	else
	{
		return ScoreType_Invalid;
	}
}