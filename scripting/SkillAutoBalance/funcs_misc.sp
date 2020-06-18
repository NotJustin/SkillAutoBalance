int GetClientCountMinusSourceTV()
{
	int count = GetClientCount(true);
	if (IsClientInGame(1) && IsClientSourceTV(1))
	{
		--count;
	}
	return count;
}
bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}
void HLStatsXStatsCallback(int command, int payload, int client, DataPack &datapack)
{
	if (client && IsClientInGame(client))
	{
		DataPack pack = view_as<DataPack>(CloneHandle(datapack));
		pack.ReadCell(); // Skipping client rank. Skill is in the next cell
		g_iClientScore[client] = float(pack.ReadCell());
	}
	delete datapack;
}
Action GameMEStatsCallback(int command, int payload, int client, Handle datapack)
{
	char param[128];
	if (6 <= GetCmdArgs())
	{
		GetCmdArg(6, param, sizeof(param));
		g_iClientScore[client] = StringToFloat(param);
	}
	else
	{
		g_iClientScore[client] = -1.0;
	}
}
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