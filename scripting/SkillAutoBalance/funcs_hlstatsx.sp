void HLStatsXStatsCallback(int command, int payload, int client, DataPack &datapack)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		datapack.Reset();
		datapack.ReadCell(); // Skipping client rank. Skill is in the next cell
		g_Players[client].score = float(datapack.ReadCell());
	}
}