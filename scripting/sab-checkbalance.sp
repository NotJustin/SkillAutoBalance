#include <sourcemod>
#include <skillautobalance/core>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "skillautobalance checkbalance",
	author = "Justin (ff)",
	description = "Module used to automatically trigger team balance at round_end if this plugin thinks it is needed",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/namenotjustin"
}

// Existing convars
ConVar
	cvar_MaxRounds,
	cvar_MinPlayers, // comes from skillautobalance
	cvar_RoundRestartDelay,
	cvar_RoundTime,
	cvar_TimeLimit
;

// Custom convars
ConVar
	cvar_NoBalanceLastNMinutes,
	cvar_NoBalanceLastNRounds,
	cvar_BalanceAfterNPlayersChange,
	cvar_BalanceAfterNRounds,
	cvar_BalanceEveryRound,
	cvar_UseDecay,
	cvar_DecayAmount,
	cvar_MinStreak
;

// Index 0 = terrorist, index 1 = counter-terrorist
float g_fTeamWinStreak[2];

int
	g_PlayerCountChange, // The amount of times the player count on server has changed since last balance (when someone joins/leaves the server). Related to sab_balanceafternplayerschange
	g_RoundCount // The amount of rounds that have passed since the map start. Related to sab_balanceafternrounds
;

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_connect_full", Event_PlayerConnectFull);
	
	cvar_MaxRounds = FindConVar("mp_maxrounds");
	cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	cvar_RoundTime = FindConVar("mp_roundtime");
	cvar_TimeLimit = FindConVar("mp_timelimit");

	cvar_BalanceAfterNRounds = CreateConVar("sab_balanceafternrounds", "0", "0 = Disabled. Otherwise, after map change balance teams when 'N' rounds pass. Then balance based on team win streaks", _, true, 0.0);
	cvar_BalanceAfterNPlayersChange = CreateConVar("sab_balanceafternplayerschange", "0", "0 = Disabled. Otherwise, balance  teams when 'N' players join/leave the server. Requires sab_balanceafternrounds to be enabled", _, true, 0.0);
	cvar_BalanceEveryRound = CreateConVar("sab_balanceeveryround", "0", "If enabled, teams will be rebalanced at the end of every round", _, true, 0.0, true, 1.0);
	cvar_DecayAmount = CreateConVar("sab_decayamount", "1.5", "The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur.", _, true, 1.0);
	cvar_MinStreak = CreateConVar("sab_minstreak", "6", "Amount of wins in a row a team needs before autobalance occurs", _, true, 0.0);
	cvar_NoBalanceLastNMinutes = CreateConVar("sab_nobalancelastnminutes", "0", "0 = Disabled. Otherwise, this is the amount of time remaining before the map ends where balancing is turned off.");
	cvar_NoBalanceLastNRounds = CreateConVar("sab_nobalancelastnrounds", "0", "0 = Disabled. Otherwise, this is the amount of rounds remaining before the map ends where balancing is turned off.");
	cvar_UseDecay = CreateConVar("sab_usedecay", "1", "If 1, subtract sab_decayamount from a team's streak when they lose instead of setting their streak to 0", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sab-checkbalance");
}

public void OnConfigsExecuted()
{
	// After all plugins are loaded, find this convar (from skillautobalance)
	cvar_MinPlayers = FindConVar("sab_minplayers");
}

public void OnMapStart()
{
	// Resetting values that determine when balance should occur at the start of every map.
	g_PlayerCountChange = 0;
	g_RoundCount = 0;
	g_fTeamWinStreak[0] = 0.0;
	g_fTeamWinStreak[1] = 0.0;
}

public void OnClientDisconnect(int client)
{
	// Increment this whenever a player leaves the server.
	++g_PlayerCountChange;
}

void Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast)
{
	// Increment this whenever a player joins the server.
	// I put this here instead of OnClientPostAdminCheck.
	// The reason is, under specific circumstances (a different module), we kick players during OnClientPostAdminCheck
	// From my experience, this event consistently occurs after OnClientPostAdminCheck.
	++g_PlayerCountChange;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// We do not want to increase round count at the end of the warmup period.
	if (!IsWarmupActive())
	{
		++g_RoundCount;
	}
	// Update the win streak of the team that won this round.
	SetStreak(event.GetInt("winner"));
	// Pass this buffer to BalanceSkillNeeded. It fills the buffer with a translation phrase, used in skillautobalance-messages
	char sReason[50];
	// BalanceSkillNeeded returns an enum. Honestly, this can just return true/false instead.
	SABBalanceReason reason = BalanceSkillNeeded(sReason);
	if (reason == SAB_NoBalance)
	{
		return;
	}
	SAB_Balance(sReason);
	// After a balance, reset team winstreaks and player count change.
	g_fTeamWinStreak[0] = 0.0;
	g_fTeamWinStreak[1] = 0.0;
	g_PlayerCountChange = 0;
}


void SetStreak(int winningTeam)
{
	// If there was no winner, we will decrease both team win streaks by 1.0.
	if (winningTeam < CS_TEAM_T)
	{
		g_fTeamWinStreak[0] = g_fTeamWinStreak[0] < 1.0 ? 0.0 : g_fTeamWinStreak[0] - 1.0;
		g_fTeamWinStreak[1] = g_fTeamWinStreak[1] < 1.0 ? 0.0 : g_fTeamWinStreak[1] - 1.0;
		return;
	}
	float decayAmount = cvar_DecayAmount.FloatValue;
	// Terrorist team index is 2, counter-terrorist team index is 3.
	// So, I map them to index 0 and 1 in this array using modulus and avoid writing the same code for each team :D
	int winnerIndex = winningTeam - 2;
	int loserIndex 	= (winningTeam + 1) % 2;
	g_fTeamWinStreak[winnerIndex] = g_fTeamWinStreak[winnerIndex] + 1.0;
	// Check if we are decaying the losing team's winstreak, or if we are completely resetting it.
	if (cvar_UseDecay.BoolValue)
	{
		g_fTeamWinStreak[loserIndex] = (g_fTeamWinStreak[loserIndex] > decayAmount) ? (g_fTeamWinStreak[loserIndex] - decayAmount) : 0.0;
	}
	else
	{
		g_fTeamWinStreak[loserIndex] = 0.0;
	}
}

SABBalanceReason BalanceSkillNeeded(char reason[50])
{
	// We are only interested in players who are on terrorist/counter-terrorist teams
	int activePlayers = GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT);
	// If there are less than 3 players on teams, balance will have absolutely no effect, so we will not balance.
	if (activePlayers < 3)
	{
		return SAB_NoBalance;
	}
	// If the team sizes are uneven, we will always balance. (eg: 1v3, which should only happen when a player leaves the server).
	if (!AreTeamsEvenlySized())
	{
		strcopy(reason, sizeof(reason), "Uneven teams");
		return SAB_Uneven;
	}
	// If there are less active players on server than the minimum allowed for balance, we will not balance.
	if(activePlayers < cvar_MinPlayers.IntValue)
	{
		return SAB_NoBalance;
	}
	// We want to determine the minimum amount of time left in the map required for a balance to occur
	// And we want to compare that to the current time left.
	int timeLeft;
	GetMapTimeLeft(timeLeft);
	// We are determining how much time a single round lasts.
	// If the current time left is less than this, we will not balance.
	// mp_roundtime is in minutes, mp_round_restart_delay is in seconds, so we convert mp_roundtime to seconds.
	// We then add these two numbers together, as a true maximum round duration in seconds.
	// Then, we check which of the two is larger: round time in seconds, or the convar sab_nobalancelastnminutes.
	// The larger one is the minimum time we will use.
	float roundTimeSeconds = cvar_RoundTime.FloatValue * 60 + cvar_RoundRestartDelay.FloatValue;
	float noBalanceTimeSeconds = cvar_NoBalanceLastNMinutes.FloatValue * 60;
	float minTime = roundTimeSeconds >= noBalanceTimeSeconds ? roundTimeSeconds : noBalanceTimeSeconds;
	// If mp_timelimit is 0, then there is infinite time and we will ignore this.
	if (cvar_TimeLimit.BoolValue && timeLeft < minTime)
	{
		return SAB_NoBalance;
	}
	// We want to determine the minimum rounds remaining in the map required for a balance to occur
	// We check if the sum of the team scores is greater than or equal to mp_maxrounds - sab_nobalancelastnrounds. If it is, we will not balance.
	// If mp_maxrounds is 0, then there are infinite rounds and we will ignore this.
	if (cvar_MaxRounds.BoolValue && cvar_NoBalanceLastNRounds.BoolValue && (GetTeamScore(CS_TEAM_T) + GetTeamScore(CS_TEAM_CT)) >= (cvar_MaxRounds.IntValue - cvar_NoBalanceLastNRounds.IntValue))
	{
		return SAB_NoBalance;
	}
	if (cvar_BalanceEveryRound.BoolValue)
	{
		strcopy(reason, sizeof(reason), "Balance every round");
		return SAB_EveryRound;
	}
	int minStreak = cvar_MinStreak.IntValue;
	// If either team has gone on a winstreak that passed the minimum streak allowed, we will balance.
	if (g_fTeamWinStreak[0] >= minStreak)
	{
		strcopy(reason, sizeof(reason), "Terrorist win streak");
		return SAB_T_Streak;
	}
	if (g_fTeamWinStreak[1] >= minStreak)
	{
		strcopy(reason, sizeof(reason), "Counter-terrorist win streak");
		return SAB_CT_Streak;
	}
	// The purpose of the following two is to balance teams when there are new players joining the server.
	// If it is a new map and the first N rounds have passed, we will balance.
	int balanceAfterNRounds = cvar_BalanceAfterNRounds.IntValue;
	if(balanceAfterNRounds && balanceAfterNRounds == g_RoundCount)
	{
		strcopy(reason, sizeof(reason), "Balance after first N rounds");
		return SAB_AfterNRounds;
	}
	// As players leave/join the server, the effect of the previous balance(s) go away.
	// When a certain amount of players change, we will balance.
	int balanceAfterNPlayersChange = cvar_BalanceAfterNPlayersChange.IntValue;
	if (balanceAfterNPlayersChange && balanceAfterNPlayersChange <= g_PlayerCountChange)
	{
		strcopy(reason, sizeof(reason), "Balance after N players change");
		return SAB_AfterNPlayersChange;
	}
	// If all previous conditions were false, there is no need for a balance.
	return SAB_NoBalance;
}

bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

// Checks which team has the fewest players, or picks a random team.
int GetSmallestTeam()
{
	int tSize = GetTeamClientCount(CS_TEAM_T);
	int ctSize = GetTeamClientCount(CS_TEAM_CT);
	return tSize == ctSize ? GetRandomInt(CS_TEAM_T, CS_TEAM_CT) : tSize < ctSize ? CS_TEAM_T : CS_TEAM_CT;
}

// Checks if the difference between team sizes is greater than 1.
bool AreTeamsEvenlySized()
{
	int teams[2] = {2, 3};
	int smallIndex = GetSmallestTeam() - 2;
	int bigIndex = (smallIndex + 1) % 2;
	return GetTeamClientCount(teams[bigIndex]) - GetTeamClientCount(teams[smallIndex]) <= 1;
}