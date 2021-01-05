void AddOutliers(int sizes[2])
{
	int client, team;
	int teams[2] = {2, 3};
	int nextTeam = (sizes[0] <= sizes[1] ? 0 : 1);
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (client && g_bClientIsOutlier[client] && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
		{
			if (GetClientTeam(client) != teams[nextTeam])
			{
				SwapPlayer(client, teams[nextTeam], "Client Skill Balance");
			}
			nextTeam = (nextTeam + 1) % 2;
		}
		g_bClientIsOutlier[client] = false;
	}
}
void BalanceSkill()
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChatAll("Global Skill Balance");
	}
	SortCustom1D(g_iClient, sizeof(g_iClient), Sort_Scores);
	int outliers = RemoveOutliers();
	int sizes[2];
	sizes = SortCloseSums(outliers);
	if (outliers > 0)
	{
		AddOutliers(sizes);
	}
}
bool BalanceSkillNeeded()
{
	int time;
	GetMapTimeLeft(time);
	int minStreak = cvar_MinStreak.IntValue;
	if (time > (cvar_RoundTime.FloatValue * 60 + cvar_RoundRestartDelay.FloatValue + 1))
	{
		if (cvar_BalanceEveryRound.BoolValue || g_fTeamWinStreak[0] >= minStreak || g_fTeamWinStreak[1] >= minStreak)
		{
			return true;
		}
		else if(cvar_BalanceAfterNRounds.BoolValue)
		{
			if (g_RoundCount == cvar_BalanceAfterNRounds.IntValue)
			{
				return true;
			}
			else if (cvar_BalanceAfterNPlayersChange.BoolValue && g_RoundCount >= cvar_BalanceAfterNRounds.IntValue)
			{
				if (g_PlayerCountChange >= cvar_BalanceAfterNPlayersChange.IntValue)
				{
					return true;
				}
			}
		}
	}
	return false;
}
float GetAverageScore()
{
	int count = GetClientCountMinusSourceTV();
	float sum = 0.0;
	int client;
	int missingScores = 0;
	int i = 0;
	int counted = 0;
	while(counted < count)
	{
		client = g_iClient[i];
		if (IsClientInGame(client) && !IsClientSourceTV(client))
		{
			++counted;
			if (g_fClientScore[client] != -1.0)
			{
				sum += g_fClientScore[client];
			}
			else
			{
				++missingScores;
			}
		}
		++i;
		if (i > MaxClients)
		{
			break;
		}
	}
	return sum / (count - missingScores);
}
int RemoveOutliers()
{
	int outliers = 0;
	int size = GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT);
	int q1Start = 0;
	int q3End = size - 1;
	float q1Med, q3Med, IQR;
	int q1End, q1Size, q3Start, q3Size;
	if (size % 2 == 0)
	{
		q1End = size / 2 - 1;
		q1Size = q1End - q1Start + 1;
		q3Start = size / 2;
		q3Size = q3End - q3Start + 1;
		if (q1Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q1Size / 2 - 1 + q1Start];
			int rightClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = (g_fClientScore[leftClientIndex] + g_fClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = g_fClientScore[medianClientIndex];
		}
		if (q3Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q3Size / 2 - 1 + q3Start];
			int rightClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = (g_fClientScore[leftClientIndex] + g_fClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = g_fClientScore[medianClientIndex];
		}
	}
	else
	{
		q1End = size / 2 - 1;
		q1Size = q1End - q1Start + 1;
		q3Start = size / 2 + 1;
		q3Size = q3End - q3Start + 1;
		if (q1Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q1Size / 2 - 1 + q1Start];
			int rightClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = (g_fClientScore[leftClientIndex] + g_fClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = g_fClientScore[medianClientIndex];
		}
		if (q3Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q3Size / 2 - 1 + q3Start];
			int rightClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = (g_fClientScore[leftClientIndex] + g_fClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = g_fClientScore[medianClientIndex];
		}
	}
	IQR = q1Med - q3Med;
	float lowerBound = q3Med - cvar_Scale.IntValue * IQR;
	float upperBound = q1Med + cvar_Scale.IntValue * IQR;
	int client, team;
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (client && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
		{
			if (IsFakeClient(client) && !cvar_BotsArePlayers.BoolValue)
			{
				g_bClientIsOutlier[client] = true;
				outliers++;
			}
			else if (g_fClientScore[client] > upperBound || g_fClientScore[client] < lowerBound)
			{
				g_bClientIsOutlier[client] = true;
				outliers++;
			}
		}
	}
	return outliers;
}
void ScrambleTeams()
{
	SortIntegers(g_iClient, sizeof(g_iClient), Sort_Random);
	int teams[2] = {2, 3};
	int nextTeam = GetSmallestTeam() - 2;
	int client, team;
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (!client || !IsClientInGame(client) || (team = GetClientTeam(client)) == TEAM_SPEC || team == UNASSIGNED)
		{
			continue;
		}
		if (GetClientTeam(client) != teams[nextTeam])
		{
			SwapPlayer(client, teams[nextTeam], "Client Scramble Team");
		}
		nextTeam = (nextTeam + 1) % 2;
	}
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
int SortCloseSums(int outliers)
{
	int sizes[2];
	int client, team;
	int i = 0;
	int totalSize = GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT) - outliers;
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
		client = g_iClient[i];
		if (client && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED && !g_bClientIsOutlier[client])
		{
			if (tSum < ctSum)
			{
				tSum += g_fClientScore[client];
				++tCount;
				if (GetClientTeam(client) == TEAM_CT)
				{
					SwapPlayer(client, TEAM_T, "Client Skill Balance");
				}
			}
			else
			{
				ctSum += g_fClientScore[client];
				++ctCount;
				if (GetClientTeam(client) == TEAM_T)
				{
					SwapPlayer(client, TEAM_CT, "Client Skill Balance");
				}
			}
		}
		++i;
	}
	while(i < sizeof(g_iClient))
	{
		client = g_iClient[i];
		if (client && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED && !g_bClientIsOutlier[client])
		{
			if (tCount < smallTeamSize)
			{
				++tCount;
				if (GetClientTeam(client) == TEAM_CT)
				{
					SwapPlayer(client, TEAM_T, "Client Skill Balance");
				}
			}
			else if (ctCount < smallTeamSize)
			{
				++ctCount;
				if(GetClientTeam(client) == TEAM_T)
				{
					SwapPlayer(client, TEAM_CT, "Client Skill Balance");
				}
			}
		}
		++i;
	}
	sizes[0] = tCount;
	sizes[1] = ctCount;
	return sizes;
}
int Sort_Scores(int client1, int client2, const int[] array, Handle hndl)
{
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
	float client1Score = g_fClientScore[client1];
	float client2Score = g_fClientScore[client2];
	if(client1Score == client2Score)
	{
		return 0;
	}
	return client1Score > client2Score ? -1 : 1;
}
void UpdateScores()
{
	int client;
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (client && IsClientInGame(client) && !IsClientSourceTV(client))
		{
			GetScore(client);
		}
	}
}
void FixMissingScores()
{
	g_LastAverageScore = GetAverageScore();
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		int client = g_iClient[i];
		if (client && IsClientInGame(client) && !IsClientSourceTV(client))
		{
			if (g_fClientScore[client] == -1.0)
			{
				g_bClientScoreUpdated[client] = true;
				g_fClientScore[client] = g_LastAverageScore;
			}
		}
	}
}