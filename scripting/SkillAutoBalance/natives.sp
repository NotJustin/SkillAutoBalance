// Whenever this native is used, a team balance will occur at the end of the round.
any Native_Balance(Handle plugin, int args)
{
	char reason[50];
	int error = GetNativeString(1, reason, sizeof(reason));
	if (error != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Error with 'reason' parameter");
		return;
	}
	g_bBalanceNeeded = true;
}

any Native_GetClientScore(Handle plugin, int args)
{
	int client = GetNativeCell(1);
	if (client < 0 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Client index %d is not valid", client);
		return -1.0;
	}
	if (client == 0)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Cannot get score of client index 0");
		return -1.0;
	}
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Client index %d is not in game", client);
		return -1.0;
	}
	return g_ClientData[client].score;
}

any Native_SwapPlayer(Handle plugin, int args)
{
	int client = GetNativeCell(1);
	int team = GetNativeCell(2);
	char reason[50];
	int error = GetNativeString(3, reason, sizeof(reason));
	if (client < 0 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Client index %d is not valid", client);
		return;
	}
	if (client == 0)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Cannot swap client index 0");
		return;
	}
	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Client index %d is not in game", client);
		return;
	}
	if (team <= CS_TEAM_NONE || team > CS_TEAM_CT) // I don't want to move players to UNASSIGNED team.
	{
		ThrowNativeError(SP_ERROR_PARAM, "Team index %d is not valid", team);
		return;
	}
	if (error != SP_ERROR_NONE)
	{
		ThrowNativeError(error, "Error with 'reason' parameter");
		return;
	}
	SwapPlayer(client, team, reason);
}