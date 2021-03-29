// The callback function for gameme, when querying player info.
Action GameMEStatsCallback(int command, int payload, int client, Handle datapack)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	char param[128];
	if (6 <= GetCmdArgs())
	{
		GetCmdArg(6, param, sizeof(param));
		g_ClientData[client].score = StringToFloat(param);
	}
	else
	{
		g_ClientData[client].score = -1.0;
	}
	return Plugin_Handled;
}

// The callback function for hlstatsx, when querying player info.
void HLStatsXStatsCallback(int command, int payload, int client, DataPack &datapack)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	datapack.Reset();
	datapack.ReadCell(); // Skipping client rank. Skill is in the next cell
	g_ClientData[client].score = float(datapack.ReadCell());
}

// A custom function for NCRPG, getting a sum of all their skill levels.
float NCRPG_GetSkillSum(int client)
{
	float score = 0.0;
	for (int i = 0; i < NCRPG_GetSkillCount(); ++i)
	{
		if (NCRPG_IsValidSkillID(i))
		{
			score += float(NCRPG_GetSkillLevel(client, i));
		}
	}
	return score;
}