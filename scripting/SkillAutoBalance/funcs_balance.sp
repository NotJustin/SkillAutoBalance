void ForceBalance(int client)
{
	g_ForceBalance = true;
	Call_StartForward(g_BalanceCommandForward);
	Call_PushCell(client);
	Call_Finish();
}

void SwapFewestPlayers()
{
	int wrongTeam = 0, correctTeam = 0;
	int teams[2] = {CS_TEAM_T, CS_TEAM_CT};
	int team;
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client))
		{
			if (g_Players[client].pendingSwap)
			{
				++wrongTeam;
			}
			else
			{
				++correctTeam;
			}
		}
	}
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE && ((wrongTeam > correctTeam) ^ g_Players[client].pendingSwap))
		{
			SwapPlayer(client, teams[(team + 1) % 2], SAB_SkillBalance);
		}
	}
}
void AssignOutliersToTeams(ArrayList sortedPlayers, int sizes[2])
{
	int team, client;
	int teams[2] = {CS_TEAM_T, CS_TEAM_CT};
	int nextTeam = (sizes[0] <= sizes[1] ? 0 : 1);
	for (int index = 0; index < sortedPlayers.Length; ++index)
	{
		client = sortedPlayers.Get(index);
		if (g_Players[client].isOutlier && IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE)
		{
			if (team != teams[nextTeam])
			{
				g_Players[client].pendingSwap = true;
			}
			nextTeam = (nextTeam + 1) % 2;
		}
		g_Players[client].isOutlier = false;
	}
}
ArrayList GetSortedPlayers()
{
	ArrayList sortedPlayers = new ArrayList();
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && !IsClientSourceTV(client))
		{
			sortedPlayers.Push(client);
		}
	}
	SortADTArrayCustom(sortedPlayers, Sort_Scores);
	return sortedPlayers;
}
void BalanceSkill()
{
	ArrayList sortedPlayers = GetSortedPlayers();
	int outliers = FindOutliers(sortedPlayers);
	int sizes[2];
	sizes = AssignPlayersToTeams(sortedPlayers, outliers);
	if (outliers > 0)
	{
		AssignOutliersToTeams(sortedPlayers, sizes);
	}
	sortedPlayers.Clear();
	delete sortedPlayers;
	SwapFewestPlayers();
	Call_StartForward(g_BalanceForward);
	Call_PushCell(balanceReason);
	Call_Finish();
}
SABBalanceReason BalanceSkillNeeded()
{
	int activePlayers = GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT);
	if (activePlayers < 3)
	{
		return SAB_NoBalance;
	}
	if (!AreTeamsEvenlySized())
	{
		return SAB_Uneven;
	}
	if(activePlayers < cvar_MinPlayers.IntValue)
	{
		return SAB_NoBalance;
	}
	if (g_ForceBalance)
	{
		return SAB_Forced;
	}
	int timeLeft;
	GetMapTimeLeft(timeLeft);
	float roundTimeMinutes = cvar_RoundTime.FloatValue * 60 + cvar_RoundRestartDelay.FloatValue + 1;
	float noBalanceTimeMinutes = cvar_NoBalanceLastNMinutes.FloatValue;
	float minTime = roundTimeMinutes >= noBalanceTimeMinutes ? roundTimeMinutes : noBalanceTimeMinutes;
	if (timeLeft < minTime)
	{
		return SAB_NoBalance;
	}
	if (cvar_NoBalanceLastNRounds.BoolValue && GetTeamScore(CS_TEAM_T) + GetTeamScore(CS_TEAM_CT) >= (cvar_MaxRounds.IntValue - cvar_NoBalanceLastNRounds.IntValue))
	{
		return SAB_NoBalance;
	}
	int minStreak = cvar_MinStreak.IntValue;
	if (cvar_BalanceEveryRound.BoolValue)
	{
		return SAB_EveryRound;
	}
	if (g_fTeamWinStreak[0] >= minStreak)
	{
		return SAB_T_Streak;
	}
	if (g_fTeamWinStreak[1] >= minStreak)
	{
		return SAB_CT_Streak;
	}
	int balanceAfterNRounds = cvar_BalanceAfterNRounds.IntValue;
	if(balanceAfterNRounds && balanceAfterNRounds == g_RoundCount)
	{
		return SAB_AfterNRounds;
	}
	int balanceAfterNPlayersChange = cvar_BalanceAfterNPlayersChange.IntValue;
	if (balanceAfterNPlayersChange && balanceAfterNPlayersChange <= g_PlayerCountChange)
	{
		return SAB_AfterNPlayersChange;
	}
	return SAB_NoBalance;
}
float GetAverageScore()
{
	int count = GetClientCountMinusSourceTV();
	float sum = 0.0;
	int missingScores = 0;
	int client = 1;
	int counted = 0;
	while(counted < count)
	{
		if (IsClientInGame(client) && !IsClientSourceTV(client))
		{
			++counted;
			if (g_Players[client].score != -1.0)
			{
				sum += g_Players[client].score;
			}
			else
			{
				++missingScores;
			}
		}
		++client;
		if (client > MaxClients)
		{
			break;
		}
	}
	return sum / (count - missingScores);
}
int FindOutliers(ArrayList sortedPlayers)
{
	int outliers = 0;
	int size = GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT);
	int q1Start = 0;
	int q3End = size - 1;
	float q1Med, q3Med, IQR;
	int q1End, q1Size, q3Start, q3Size;
	q1End = size / 2 - 1;
	q1Size = q1End - q1Start + 1;
	q3Start = (size % 2 == 0) ? size / 2 : size / 2 + 1;
	q3Size = q3End - q3Start + 1;
	if (q1Size % 2 == 0)
	{
		int leftClient = sortedPlayers.Get(q1Size / 2 - 1 + q1Start);
		int rightClient = sortedPlayers.Get(q1Size / 2 + q1Start);
		q1Med = g_Players[leftClient].score + g_Players[rightClient].score / 2;
	}
	else
	{
		int medianClient = sortedPlayers.Get(q1Size / 2 + q1Start);
		q1Med = g_Players[medianClient].score;
	}
	if (q3Size % 2 == 0)
	{
		int leftClient = sortedPlayers.Get(q3Size / 2 - 1 + q3Start);
		int rightClient = sortedPlayers.Get(q3Size / 2 + q3Start);
		q3Med = g_Players[leftClient].score + g_Players[rightClient].score / 2;
	}
	else
	{
		int medianClient = sortedPlayers.Get(q3Size / 2 + q3Start);
		q3Med = g_Players[medianClient].score;
	}
	IQR = q1Med - q3Med;
	float lowerBound = q3Med - cvar_Scale.IntValue * IQR;
	float upperBound = q1Med + cvar_Scale.IntValue * IQR;
	int team;
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE)
		{
			if (IsFakeClient(client) && !cvar_BotsArePlayers.BoolValue)
			{
				g_Players[client].isOutlier = true;
				outliers++;
			}
			else if (g_Players[client].score > upperBound || g_Players[client].score < lowerBound)
			{
				g_Players[client].isOutlier = true;
				outliers++;
			}
		}
	}
	return outliers;
}
void SetStreak(int winningTeam)
{
	if (winningTeam >= 2)
	{
		float decayAmount = cvar_DecayAmount.FloatValue;
		int winnerIndex = winningTeam - 2;
		int loserIndex 	= (winningTeam + 1) % 2;
		++g_fTeamWinStreak[winnerIndex];
		if (cvar_UseDecay.BoolValue)
		{
			g_fTeamWinStreak[loserIndex] = (g_fTeamWinStreak[loserIndex] > decayAmount) ? (g_fTeamWinStreak[loserIndex] - decayAmount) : 0.0;
		}
		else
		{
			g_fTeamWinStreak[loserIndex] = 0.0;
		}
	}
}
int AssignPlayersToTeams(ArrayList sortedPlayers, int outliers)
{
	int sizes[2];
	int team, client;
	int i = 0;
	int totalSize = GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT) - outliers;
	int smallTeamSize = totalSize / 2;
	int bigTeamSize = smallTeamSize;
	if (totalSize % 2 == 1)
	{
		++bigTeamSize;
	}
	float tSum = 0.0;
	float ctSum = 0.0;
	int tCount = 0;
	int ctCount = 0;
	while(tCount < bigTeamSize && ctCount < bigTeamSize)
	{
		client = sortedPlayers.Get(i);
		if (IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE && !g_Players[client].isOutlier)
		{
			if (tSum < ctSum)
			{
				tSum += g_Players[client].score;
				++tCount;
				if (team == CS_TEAM_CT)
				{
					g_Players[client].pendingSwap = true;
				}
			}
			else
			{
				ctSum += g_Players[client].score;
				++ctCount;
				if (team == CS_TEAM_T)
				{
					g_Players[client].pendingSwap = true;
				}
			}
		}
		++i;
	}
	while(i < sortedPlayers.Length)
	{
		client = sortedPlayers.Get(i);
		if (IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE && !g_Players[client].isOutlier)
		{
			if (tCount < smallTeamSize)
			{
				++tCount;
				if (team == CS_TEAM_CT)
				{
					g_Players[client].pendingSwap = true;
				}
			}
			else if (ctCount < smallTeamSize)
			{
				++ctCount;
				if(team == CS_TEAM_T)
				{
					g_Players[client].pendingSwap = true;
				}
			}
		}
		++i;
	}
	sizes[0] = tCount;
	sizes[1] = ctCount;
	return sizes;
}
int Sort_Scores(int index1, int index2, Handle array, Handle hndl)
{
	int client1 = view_as<ArrayList>(array).Get(index1);
	int client2 = view_as<ArrayList>(array).Get(index2);
	if (IsClientInGame(client1) && !IsClientInGame(client2))
	{
		return -1;
	}
	else if (!IsClientInGame(client1) && IsClientInGame(client2))
	{
		return 1;
	}
	else if (!IsClientInGame(client1) && !IsClientInGame(client2))
	{
		return 0;
	}
	if (!cvar_BotsArePlayers.BoolValue)
	{
		if (!IsFakeClient(client1) && IsFakeClient(client2))
		{
			return -1;
		}
		else if (IsFakeClient(client1) && !IsFakeClient(client2))
		{
			return 1;
		}
		else if (IsFakeClient(client1) && IsFakeClient(client2))
		{
			return 0;
		}
	}
	if(g_Players[client1].score == g_Players[client2].score)
	{
		return 0;
	}
	return g_Players[client1].score > g_Players[client2].score ? -1 : 1;
}
void UpdateScores()
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && !IsClientSourceTV(client))
		{
			GetClientScore(client);
		}
	}
}
void FixMissingScores()
{
	g_LastAverageScore = GetAverageScore();
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && !IsClientSourceTV(client))
		{
			if (g_Players[client].score == -1.0)
			{
				g_Players[client].scoreUpdated = true;
				g_Players[client].score = g_LastAverageScore;
			}
		}
	}
}