public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (g_ScoreType == ScoreType_Invalid && view_as<SABScoreType>(cvar_ScoreType.IntValue) == ScoreType_Auto) // If we automatically set scoretype and haven't found one yet, find one now.
	{
		if (StrEqual(name, "gameme"))
		{
			g_ScoreType = ScoreType_gameME;
		}
		else if (StrEqual(name, "hlstatsx_api"))
		{
			g_ScoreType = ScoreType_HLstatsX;
		}
		else if (StrEqual(name, "kento_rankme"))
		{
			g_ScoreType = ScoreType_KentoRankMe;
		}
		else if (StrEqual(name, "levelsranks"))
		{
			g_ScoreType = ScoreType_LevelsRanks;
		}
		else if (StrEqual(name, "NCRPG"))
		{
			g_ScoreType = ScoreType_NCRPG;
		}
		else if (StrEqual(name, "sab_rating"))
		{
			g_ScoreType = ScoreType_SABRating;
		}
		else if (StrEqual(name, "smrpg"))
		{
			g_ScoreType = ScoreType_SMRPG;
		}
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (g_ScoreType != ScoreType_Invalid && view_as<SABScoreType>(cvar_ScoreType.IntValue) == ScoreType_Auto) // If we automatically set scoretype, check if one has unloaded.
	{
		if (StrEqual(name, "gameme") || StrEqual(name, "hlstatsx_api") || StrEqual(name, "kento_rankme") || StrEqual(name, "levelsranks") || StrEqual(name, "NCRPG") || StrEqual(name, "sab_rating") || StrEqual(name, "smrpg"))
		{
			SABScoreType scoreType = FindScoreType(); // If it has unloaded, find a new scoretype to use.
			if (scoreType != ScoreType_Invalid)
			{
				g_ScoreType = scoreType;
			}
			else
			{
				LogError("Last scoretype was unloaded, and no replacement is currently loaded");
			}
		}
	}
}

SABScoreType FindScoreType()
{
	if (LibraryExists("gameme"))
	{
		return ScoreType_gameME;
	}
	else if (LibraryExists("hlstatsx_api"))
	{
		return ScoreType_HLstatsX;
	}
	else if (LibraryExists("kento_rankme"))
	{
		return ScoreType_KentoRankMe;
	}
	else if (LibraryExists("levelsranks"))
	{
		return ScoreType_LevelsRanks;
	}
	else if (LibraryExists("NCRPG"))
	{
		return ScoreType_NCRPG;
	}
	else if (LibraryExists("sab_rating"))
	{
		return ScoreType_SABRating;
	}
	else if (LibraryExists("smrpg"))
	{
		return ScoreType_SMRPG;
	}
	else
	{
		return ScoreType_Invalid;
	}
}