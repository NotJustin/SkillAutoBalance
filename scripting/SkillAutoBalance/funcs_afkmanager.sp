void AFKM_OnClientBack(int client)
{
	if (cvar_BlockTeamSwitch.IntValue == 2 && client && IsClientInGame(client))
	{
		int team = GetClientTeam(client);
		if (team != TEAM_T && team != TEAM_CT)
		{
			if (cvar_DisplayChatMessages.BoolValue)
			{
				ColorPrintToChat(client, "AFK Return");
			}
			PutClientOnATeam(client);
		}
	}
}