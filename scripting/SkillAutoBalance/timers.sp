Action Timer_GraceTimeOver(Handle timer)
{
	g_AllowSpawn = false;
	return Plugin_Handled;
}
Action Timer_KickClient(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		KickClient(client, "%t", "Kicked Because Teams Full");
	}
}
Action Timer_UnpacifyPlayer(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);
	g_Players[client].isPassive = false;
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		/*
		 * delaying god removal to prevent players from being killed in last frame.
		 * I worry this makes them immortal very briefly on round start.
		 * However, I don't think it is normal for players to die immediately when they spawn anyway.
		**/
		RequestFrame(RemoveGod, userID);
	}
	return Plugin_Handled;
}

Action Timer_DelayBalance(Handle timer)
{
	FixMissingScores();
	BalanceSkill();
}

void RemoveGod(int userID)
{
	int client = GetClientOfUserId(userID);
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}