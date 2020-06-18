bool AreTeamsEmpty()
{
	return !(GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT));
}
void BalanceTeamCount()
{
	int teams[2] = {2, 3};
	int smallIndex = GetSmallestTeam() - 2;
	int bigIndex = (smallIndex + 1) % 2;
	int client;
	int i = 0;
	SortIntegers(g_iClient, sizeof(g_iClient), Sort_Random);
	while(i < sizeof(g_iClient) && (GetTeamClientCount(teams[bigIndex]) - GetTeamClientCount(teams[smallIndex]) > 1))
	{
		client = g_iClient[i];
		if (client && IsClientInGame(client) && GetClientTeam(client) == teams[bigIndex])
		{
			SwapPlayer(client, teams[smallIndex], "Team Count Balance");
		}
		++i;
	}
}
int GetSmallestTeam()
{
	int tSize = GetTeamClientCount(TEAM_T);
	int ctSize = GetTeamClientCount(TEAM_CT);
	return tSize == ctSize ? GetRandomInt(TEAM_T, TEAM_CT) : tSize < ctSize ? TEAM_T : TEAM_CT;
}