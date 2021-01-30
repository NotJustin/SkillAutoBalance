Action GameMEStatsCallback(int command, int payload, int client, Handle datapack)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		char param[128];
		if (g_Players[client].scoreUpdated)
		{
			return Plugin_Handled;
		}
		g_Players[client].scoreUpdated = true;
		if (6 <= GetCmdArgs())
		{
			GetCmdArg(6, param, sizeof(param));
			g_Players[client].score = StringToFloat(param);
		}
		else
		{
			g_Players[client].score = -1.0;
		}
	}
	return Plugin_Handled;
}