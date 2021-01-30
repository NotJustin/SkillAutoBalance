enum struct SABPlayerData 
{
	int team;
	int forceJoinPreference;

	bool fullyConnected;
	bool isPassive;
	bool isOutlier;
	bool pendingSwap;
	bool pendingForceJoin;
	bool postAdminChecked;
	bool scoreUpdated;

	float score;
}

SABPlayerData g_Players[MAXPLAYERS + 1];

bool
	g_AllowSpawn = true,
	g_ForceBalance,
	g_SetTeamHooked,
	g_ForceBalanceHooked,
	g_LateLoad,
	g_MapLoaded
;

float
	g_fTeamWinStreak[2],
	g_LastAverageScore = 1000.0
;

Handle g_hForceSpawn;

int
	g_PlayerCountChange,
	g_RoundCount
;