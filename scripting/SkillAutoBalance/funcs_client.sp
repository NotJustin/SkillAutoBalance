void PacifyPlayer(int client)
{
	if(cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Pacified Client");
	}
	CS_UpdateClientModel(client);
	g_iClientFrozen[client] = true;
	SetEntityRenderColor(client, 0, 170, 174, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer(cvar_RoundRestartDelay.FloatValue, Timer_UnpacifyPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
void SwapPlayer(int client, int team, char reason[50])
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, reason);
	}
	g_iClientTeam[client] = team;
	if(team != TEAM_SPEC && team != UNASSIGNED)
	{
		if (IsPlayerAlive(client) && cvar_KeepPlayersAlive.BoolValue)
		{
			CS_SwitchTeam(client, team);
			CS_UpdateClientModel(client);
			PacifyPlayer(client);
			return;
		}
		ChangeClientTeam(client, team);
		return;
	}
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	ChangeClientTeam(client, TEAM_SPEC);
}
bool CanJoin(int client, int team, bool printMessage)
{
	int count[2];
	count[0] = GetTeamClientCount(TEAM_T);
	count[1] = GetTeamClientCount(TEAM_CT);
	int newTeamCount = count[team - 2];
	int otherTeamCount = count[(team + 1) % 2];
	int currentTeam = GetClientTeam(client);
	if (newTeamCount > otherTeamCount)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Team Has More Players");
		}
		return false;
	}
	else if (newTeamCount == otherTeamCount && g_iClientTeam[client] == team)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Must Join Previous Team");
		}
		return true;
	}
	else if (newTeamCount < otherTeamCount && currentTeam != TEAM_T && currentTeam != TEAM_CT)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Must Join Previous Team");
		}
		return true;
	}
	return false;
}