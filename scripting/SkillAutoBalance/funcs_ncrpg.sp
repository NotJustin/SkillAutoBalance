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