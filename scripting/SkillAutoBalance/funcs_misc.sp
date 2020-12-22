int GetClientCountMinusSourceTV()
{
	int count = GetClientCount(true);
	if (IsClientInGame(1) && IsClientSourceTV(1))
	{
		--count;
	}
	return count;
}
bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}
Action PrintHowToJoinForSpectators()
{
	for(int i = 0; i < sizeof(g_iClient); ++i)
	{
		int client = g_iClient[i];
		if (IsClientInGame(client))
		{
			int team = GetClientTeam(client);
			if (team != TEAM_T && team != TEAM_CT)
			{
				ColorPrintToChat(client, "Team Menu Disabled");
			}
		}
	}
}