void RegCommands()
{
	RegConsoleCmd("sm_j", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_join", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_p", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_play", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_s", Command_Spectate, "Switches player to spectator team");
	RegConsoleCmd("sm_spec", Command_Spectate, "Switches player to spectator team");
	RegConsoleCmd("sm_spectate", Command_Spectate, "Switches player to spectator team");
}
Action Command_Join(int client, int args)
{
	int team;
	if (cvar_ChatChangeTeam.BoolValue && (cvar_BlockTeamSwitch.IntValue != 2) && client && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_T && team != TEAM_CT)
	{
		if (g_iClientTeam[client] == TEAM_SPEC || g_iClientTeam[client] == UNASSIGNED)
		{
			SwapPlayer(client, GetSmallestTeam(), "Auto Join");
		}
		else if (CanJoin(client, g_iClientTeam[client], false))
		{
			SwapPlayer(client, g_iClientTeam[client], "Auto Join");
		}
		else if (g_iClientTeam[client] == TEAM_T)
		{
			SwapPlayer(client, TEAM_CT, "Auto Join");
		}
		else
		{
			SwapPlayer(client, TEAM_T, "Auto Join");
		}
	}
	return Plugin_Handled;
}
Action Command_Spectate(int client, int args)
{
	int team;
	if (cvar_ChatChangeTeam.BoolValue && (cvar_BlockTeamSwitch.IntValue != 2) && client && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
		ChangeClientTeam(client, TEAM_SPEC);
	}
	return Plugin_Handled;
}
Action Command_Balance(int client, int args)
{
	g_ForceBalance = true;
	if (!client)
	{
		PrefixPrintToServer("Admin Force Balance");
	}
	else if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Admin Force Balance");
	}
	return Plugin_Handled;
}
Action Command_SetTeam(int client, int args)
{
	if (args < 2)
	{
		if (!client)
		{
			PrefixPrintToServer("Incorrect SetTeam Usage");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Incorrect SetTeam Usage");
		}
		return Plugin_Handled;
	}
	char buff[32];
	GetCmdArg(1, buff, sizeof(buff));
	int client1 = FindTarget(client, buff);
	if (client1 == -1)
	{
		if (!client)
		{
			PrefixPrintToServer("Client Not Found");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Client Not Found");
		}
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(2, buff, sizeof(buff));
		if (strcmp(buff, "ct", false) == 0 || strcmp(buff, "3", false) == 0)
		{
			SwapPlayer(client1, TEAM_CT, "Admin Join");
		}
		else if(strcmp(buff, "t", false) == 0 || strcmp(buff, "2", false) == 0)
		{
			SwapPlayer(client1, TEAM_T, "Admin Join");
		}
		else if (strcmp(buff, "spec", false) == 0 || strcmp(buff, "1", false) == 0)
		{
			SwapPlayer(client1, TEAM_SPEC, "Admin Join");
		}
		if (!client)
		{
			PrefixPrintToServer("Admin Client Swapped");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Admin Client Swapped");
		}
		return Plugin_Handled;
	}
}

/* Command Listeners */
Action CommandList_JoinTeam(int client, const char[] command, int argc)
{
	if (cvar_BlockTeamSwitch.IntValue == 0)
	{
		RequestFrame(DelayTeamUpdate, GetClientUserId(client));
		return Plugin_Continue;
	}
	if (g_iClientForceJoin[client])
	{
		g_iClientForceJoin[client] = false;
		RequestFrame(DelayTeamUpdate, GetClientUserId(client));
		return Plugin_Continue;
	}
	if (cvar_BlockTeamSwitch.IntValue == 2)
	{
		return Plugin_Stop;
	}
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	int team = StringToInt(arg);
	if (team == UNASSIGNED)
	{
		return Plugin_Stop;
	}
	if (team == TEAM_SPEC)
	{
		return Plugin_Continue;
	}
	if (!CanJoin(client, team, true))
	{
		return Plugin_Stop;
	}
	RequestFrame(DelayTeamUpdate, GetClientUserId(client));
	return Plugin_Continue;
}