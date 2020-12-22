void InitializeClient(int client)
{
	if (AreClientCookiesCached(client))
	{
		OnClientCookiesCached(client);
	}
	g_iClientTeam[client] = TEAM_SPEC;
	g_iClientScoreUpdated[client] = false;
	g_iClientScore[client] = -1.0;
	g_iClientFrozen[client] = false;
	g_iClientOutlier[client] = false;
	++g_PlayerCountChange;
	if (!cvar_TeamMenu.BoolValue && cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Team Menu Disabled");
	}
	bool teamsFull = false;
	if (!(teamsFull = AreTeamsFull()) && (cvar_ForceJoinTeam.IntValue == 1 && g_iClientForceJoinPreference[client] == 1) || cvar_ForceJoinTeam.IntValue == 2 || (!cvar_ChatChangeTeam.BoolValue && !cvar_TeamMenu.BoolValue && cvar_BlockTeamSwitch.IntValue > 0))
	{
		g_iClientForceJoin[client] = true;
		int team = GetSmallestTeam();
		ClientCommand(client, "jointeam 0 %i", team);
		if (!IsPlayerAlive(client) && (GetClientTeam(client) == TEAM_T || GetClientTeam(client) == TEAM_CT) && (g_AllowSpawn || AreTeamsEmpty()))
		{
			CS_RespawnPlayer(client);
		}
	}
	else
	{
		if (teamsFull)
		{
			ColorPrintToChat(client, "Teams Are Full");
		}
		ClientCommand(client, "spectate");
		g_iClientForceJoin[client] = false;
	}
}
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
	CreateTimer((cvar_RoundRestartDelay.FloatValue - CHECKSCORE_DELAY), Timer_UnpacifyPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
void SwapPlayer(int client, int team, char reason[50])
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, reason);
	}
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