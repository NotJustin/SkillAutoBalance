int GetClientCountMinusSourceTV()
{
	for (int i = 1; i < MaxClients; ++i)
	{
		if (i && IsClientInGame(i) && IsClientSourceTV(i))
		{
			return GetClientCount(true) - 1;
		}
	}
	return GetClientCount(true);
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