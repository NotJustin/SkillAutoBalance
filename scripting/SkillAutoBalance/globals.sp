enum struct SABClientData
{
	bool isPassive;
	bool scoreUpdated;
	float score;
	void Reset()
	{
		this.isPassive = false;
		this.scoreUpdated = false;
		this.score = -1.0;
	}
}

SABClientData g_ClientData[MAXPLAYERS + 1];

bool g_bBalanceNeeded;
char g_sBalanceReason[50];

// Existing convars
ConVar
	cvar_AutoTeamBalance,
	cvar_LimitTeams,
	cvar_RoundRestartDelay
;

// Custom convars
ConVar
	cvar_BotsArePlayers,
	cvar_KeepPlayersAlive,
	cvar_ScoreType
;

float g_LastAverageScore = 1000.0;

GlobalForward
	g_BalanceForward,
	g_PacifyForward,
	g_SwapForward
;

SABScoreType g_ScoreType;