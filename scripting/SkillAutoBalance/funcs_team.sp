bool AreTeamsEmpty()
{
	return !(GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT));
}
bool AreTeamsFull()
{
	return cvar_BlockTeamSwitch.IntValue == 2 && cvar_MaxTeamSize.BoolValue && GetClientCount(true) > 1 && GetTeamClientCount(TEAM_T) == cvar_MaxTeamSize.IntValue && GetTeamClientCount(TEAM_CT) == cvar_MaxTeamSize.IntValue;
}
int GetSmallestTeam()
{
	int tSize = GetTeamClientCount(TEAM_T);
	int ctSize = GetTeamClientCount(TEAM_CT);
	return tSize == ctSize ? GetRandomInt(TEAM_T, TEAM_CT) : tSize < ctSize ? TEAM_T : TEAM_CT;
}
bool AreTeamsEvenlySized()
{
	int teams[2] = {2, 3};
	int smallIndex = GetSmallestTeam() - 2;
	int bigIndex = (smallIndex + 1) % 2;
	return GetTeamClientCount(teams[bigIndex]) - GetTeamClientCount(teams[smallIndex]) <= 1;
}