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
	bool success = true;
	if (AreTeamsFull())
	{
		success = false;
	}
	if (success && cvar_ChatChangeTeam.BoolValue && cvar_BlockTeamSwitch.IntValue != 2 && client > 0 && client <= MaxClients && IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_T && team != CS_TEAM_CT)
	{
		PutClientOnATeam(client);
	}
	Call_StartForward(g_JoinForward);
	Call_PushCell(client);
	Call_PushCell(success);
	Call_Finish();
	return Plugin_Handled;
}
Action Command_Spectate(int client, int args)
{
	int team;
	if (cvar_ChatChangeTeam.BoolValue && (cvar_BlockTeamSwitch.IntValue != 2) && client > 0 && client <= MaxClients && IsClientInGame(client) && (team = GetClientTeam(client)) != CS_TEAM_SPECTATOR && team != CS_TEAM_NONE)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}
	return Plugin_Handled;
}
Action Command_Balance(int client, int args)
{
	ForceBalance(client);
	return Plugin_Handled;
}
Action Command_SetTeam(int client, int args)
{
	SABSetTeamResult result;
	int target = -1;
	if (args < 2)
	{
		result = SAB_SetTeamIncorrectUsage;
	}
	else
	{
		char buff[32];
		GetCmdArg(1, buff, sizeof(buff));
		target = FindTarget(client, buff);
		if (target == -1)
		{
			result = SAB_SetTeamClientNotFound;
		}
		else
		{
			result = SAB_SetTeamSuccess;
			GetCmdArg(2, buff, sizeof(buff));
			if (strcmp(buff, "ct", false) == 0 || strcmp(buff, "3", false) == 0)
			{
				SwapPlayer(target, CS_TEAM_CT, SAB_AdminSetTeam);
			}
			else if(strcmp(buff, "t", false) == 0 || strcmp(buff, "2", false) == 0)
			{
				SwapPlayer(target, CS_TEAM_T, SAB_AdminSetTeam);
			}
			else if (strcmp(buff, "spec", false) == 0 || strcmp(buff, "1", false) == 0)
			{
				SwapPlayer(target, CS_TEAM_SPECTATOR, SAB_AdminSetTeam);
			}
		}
	}
	Call_StartForward(g_SetTeamForward);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(result);
	Call_Finish();
	return Plugin_Handled;
}

/* Command Listeners */
Action CommandList_JoinTeam(int client, const char[] command, int argc)
{
	if (cvar_BlockTeamSwitch.IntValue == 0 || (GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT)) < cvar_MinPlayers.IntValue)
	{
		return Plugin_Continue;
	}
	if (g_Players[client].pendingForceJoin)
	{
		g_Players[client].pendingForceJoin = false;
		return Plugin_Continue;
	}
	if (cvar_BlockTeamSwitch.IntValue == 2)
	{
		return Plugin_Stop;
	}
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	int team = StringToInt(arg);
	if (team == CS_TEAM_NONE)
	{
		return Plugin_Stop;
	}
	if (team == CS_TEAM_SPECTATOR)
	{
		return Plugin_Continue;
	}
	SABJoinTeamResult result;
	if ((result = CanJoin(client, team)) != SAB_JoinTeamSuccess)
	{
		Call_StartForward(g_JoinTeamForward);
		Call_PushCell(client);
		Call_PushCell(result);
		Call_Finish();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}