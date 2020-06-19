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