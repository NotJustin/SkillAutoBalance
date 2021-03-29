enum struct SABClientData
{
	bool isPassive;
	float score;
	void Reset()
	{
		this.isPassive = false;
		this.score = -1.0;
	}
}

SABClientData g_ClientData[MAXPLAYERS + 1];

bool g_bBalanceNeeded;
bool g_bConfigsExecuted;
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

float g_LastAverageScore;

GlobalForward
	g_BalanceForward,
	g_PacifyForward,
	g_SwapForward
;

SABScoreType g_ScoreType;