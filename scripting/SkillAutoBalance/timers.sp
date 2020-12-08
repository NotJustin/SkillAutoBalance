void DelayTeamUpdate(int userId) //This is for a RequestFrame. Whatever
{
	int client = GetClientOfUserId(userId);
	if (client && IsClientInGame(client))
	{
		g_iClientTeam[client] = GetClientTeam(client);
	}
}
Action Timer_CheckScore(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (client && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		if (g_iClientScore[client] == -1.0)
		{
			g_iClientScoreUpdated[client] = true;
			g_iClientScore[client] = g_LastAverageScore;
		}
		if (g_Balancing)
		{
			++g_PlayerCount;
			if (g_PlayerCount == GetClientCountMinusSourceTV())
			{
				FixMissingScores();
				BalanceSkill();
				g_PlayerCount = 0;
			}
		}
	}
	return Plugin_Handled;
}
Action Timer_GraceTimeOver(Handle timer)
{
	g_AllowSpawn = false;
	return Plugin_Handled;
}
Action Timer_UnpacifyPlayer(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);
	g_iClientFrozen[client] = false;
	if(client && IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Handled;
}