bool AreTeamsEmpty()
{
	return !(GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT));
}
bool AreTeamsFull()
{
	return cvar_BlockTeamSwitch.IntValue == 2 && cvar_MaxTeamSize.BoolValue && GetClientCount(true) > 1 && GetTeamClientCount(CS_TEAM_T) == cvar_MaxTeamSize.IntValue && GetTeamClientCount(CS_TEAM_CT) == cvar_MaxTeamSize.IntValue;
}
int GetSmallestTeam()
{
	int tSize = GetTeamClientCount(CS_TEAM_T);
	int ctSize = GetTeamClientCount(CS_TEAM_CT);
	return tSize == ctSize ? GetRandomInt(CS_TEAM_T, CS_TEAM_CT) : tSize < ctSize ? CS_TEAM_T : CS_TEAM_CT;
}
bool AreTeamsEvenlySized()
{
	int teams[2] = {2, 3};
	int smallIndex = GetSmallestTeam() - 2;
	int bigIndex = (smallIndex + 1) % 2;
	return GetTeamClientCount(teams[bigIndex]) - GetTeamClientCount(teams[smallIndex]) <= 1;
}