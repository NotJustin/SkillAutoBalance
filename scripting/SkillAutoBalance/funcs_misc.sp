int GetClientCountMinusSourceTV()
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && IsClientSourceTV(client))
		{
			return GetClientCount(true) - 1;
		}
	}
	return GetClientCount(true);
}
bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}