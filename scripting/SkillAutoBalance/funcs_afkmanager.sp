public void AFKM_OnClientBack(int client)
{
	if (cvar_BlockTeamSwitch.IntValue == 2 && client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		int team = GetClientTeam(client);
		if (team != CS_TEAM_T && team != CS_TEAM_CT)
		{
			Call_StartForward(g_AFKReturnForward);
			Call_PushCell(client);
			Call_Finish();
			PutClientOnATeam(client);
		}
	}
}