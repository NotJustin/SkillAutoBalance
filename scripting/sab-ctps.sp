#include <sourcemod>
#include <skillautobalance/core>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "skillautobalance ctps",
	author = "Justin (ff)",
	description = "'Close team point sums'. Module used to decide how teams should be balanced.",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/namenotjustin"
}

enum struct SABClientData
{
	bool isOutlier;
	bool isPendingSwap;
}

SABClientData g_ClientData[MAXPLAYERS + 1];

// Existing convars
ConVar cvar_BotsArePlayers; // From skillautobalance

// Custom convars
ConVar cvar_Scale;

public void OnPluginStart()
{
	cvar_Scale = CreateConVar("sab_scale", "1.5", "Value to multiply IQR by. If your points have low spread keep this number. If your points have high spread change this to a lower number, like 0.5", _, true, 0.1);
	AutoExecConfig(true, "sab-ctps");
}

public void OnConfigsExecuted()
{
	// After all plugins are loaded, find this convar (from skillautobalance)
	cvar_BotsArePlayers = FindConVar("sab_botsareplayers");
}

public void SAB_OnSkillBalance(ArrayList &sortedPlayers, char reason[50])
{
	// When a skill balance occurs, this plugin will assign players to teams.
	// Basically, this plugin is the one responsible for the skill balance.
	// The way this balance works is, given the list of sorted players, we first:
	// FindOutliers, which deterines if the players at the high/low end of the list are outliers.
	// AssignPlayersToTeams, which uses a 'close team point sum' approximation to mark non-outliers as needing a team swap.
	// AssignOutliersToTeams, which just alternates the outliers onto different teams.
	// SwapFewestPlayers, which either swaps all the players who are marked as needing a team swap, or,
	// swaps all the players who are NOT marked as needing a team swap, depending on which group of players is smaller.
	int outliers = FindOutliers(sortedPlayers);
	int sizes[2];
	float sums[2];
	AssignPlayersToTeams(sortedPlayers, outliers, sizes, sums);
	if (outliers > 0)
	{
		AssignOutliersToTeams(sortedPlayers, sizes, sums);
	}
	SwapFewestPlayers(sortedPlayers);
}

// Identifies outliers with the IQR method. If you don't know what it is, google it :D
// I am not confident enough in my own ability to explain what IQR is.
// The explanation I provide is minimal.
int FindOutliers(ArrayList sortedPlayers)
{
	int outliers = 0;
	int size = sortedPlayers.Length;
	int q1Start = 0;
	int q3End = size - 1;
	float q1Med, q3Med, IQR;
	int q1End, q1Size, q3Start, q3Size;
	q1End = size / 2 - 1;
	q1Size = q1End - q1Start + 1;
	q3Start = (size % 2 == 0) ? size / 2 : size / 2 + 1;
	q3Size = q3End - q3Start + 1;
	// If a quartile is evenly sized, there is no "middle" client for that quartile.
	// So, we get the average score of the two clients who are closest to the middle.
	if (q1Size % 2 == 0)
	{
		int leftClient = sortedPlayers.Get(q1Size / 2 - 1 + q1Start);
		int rightClient = sortedPlayers.Get(q1Size / 2 + q1Start);
		q1Med = (SAB_GetClientScore(leftClient) + SAB_GetClientScore(rightClient)) / 2;
	}
	else
	{
		int medianClient = sortedPlayers.Get(q1Size / 2 + q1Start);
		q1Med = SAB_GetClientScore(medianClient);
	}
	if (q3Size % 2 == 0)
	{
		int leftClient = sortedPlayers.Get(q3Size / 2 - 1 + q3Start);
		int rightClient = sortedPlayers.Get(q3Size / 2 + q3Start);
		q3Med = (SAB_GetClientScore(leftClient) + SAB_GetClientScore(rightClient)) / 2;
	}
	else
	{
		int medianClient = sortedPlayers.Get(q3Size / 2 + q3Start);
		q3Med = SAB_GetClientScore(medianClient);
	}
	// The IQR is the difference between the scores of the first quartile median and the third quartile median.
	IQR = q1Med - q3Med;
	// We create an upper and lower bound. Scores outside of these bounds are outliers.
	// We multiply the IQR by sab_scale. This is for situations where the point-system being used is very spread apart.
	// Higher scale means larger bounds. It is more lenient on what we consider to be "not an outlier".
	// Lower scale means smaller bounds. It is more strict on what we consider to be "not an outlier".
	// The scale value you should use is up to your own judgement.
	float lowerBound = q3Med - cvar_Scale.IntValue * IQR;
	float upperBound = q1Med + cvar_Scale.IntValue * IQR;
	int client;
	float score;
	for (int i = 0; i < sortedPlayers.Length; ++i)
	{
		client = sortedPlayers.Get(i);
		// Bots are always marked as outliers, unless sab_botsareplayers is true (meaning, bots have their own scores).
		// If somehow cvar_BotsArePlayers is null, also assume bots are outliers.
		if (IsFakeClient(client) && (cvar_BotsArePlayers == null || !cvar_BotsArePlayers.BoolValue))
		{
			g_ClientData[client].isOutlier = true;
			outliers++;
			continue;
		}
		score = SAB_GetClientScore(client);
		if (score > upperBound || score < lowerBound)
		{
			g_ClientData[client].isOutlier = true;
			outliers++;
			continue;
		}
		g_ClientData[client].isOutlier = false;
	}
	return outliers;
}

// Reearranges teams so that the sum of the client scores on each team is close.
// An approximation, not guaranteed to be as close as possible.
// Also, not necessarily the best way of balancing teams.
void AssignPlayersToTeams(ArrayList sortedPlayers, int outliers, int sizes[2], float sums[2])
{
	int client;
	int totalSize = sortedPlayers.Length - outliers;
	int smallTeamSize = totalSize / 2;
	int bigTeamSize = totalSize % 2 == 0 ? smallTeamSize : smallTeamSize + 1;
	for (int i = 0; i < sortedPlayers.Length; ++i)
	{
		client = sortedPlayers.Get(i);
		// Skip outliers
		if (g_ClientData[client].isOutlier)
		{
			continue;
		}
		// Assigns players to teams until one of the teams reaches the maximum team size.
		// This is necessary, to avoid uneven team sizes. We want 5v5 or 5v6, not 4v6 or 4v7.
		if (sizes[0] < bigTeamSize && sizes[1] < bigTeamSize)
		{
			if (sums[0] < sums[1])
			{
				sums[0] += SAB_GetClientScore(client);
				++sizes[0];
				g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_CT;
			}
			else
			{
				sums[1] += SAB_GetClientScore(client);
				++sizes[1];
				g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_T;
			}
			continue;
		}
		// When one team reaches the maximum team size, dump the remaining players onto the other team.
		// Usually this will only occur at the final iteration (so, only once).
		if (sizes[0] < smallTeamSize)
		{
			sums[0] += SAB_GetClientScore(client);
			++sizes[0];
			g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_CT;
		}
		else
		{
			sums[1] += SAB_GetClientScore(client);
			++sizes[1];
			g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_T;
		}
	}
}

// After rearranging teams, check if the outlier-players need their teams to be changed.
void AssignOutliersToTeams(ArrayList sortedPlayers, int sizes[2], float sums[2])
{
	int client;
	int teams[2] = {CS_TEAM_T, CS_TEAM_CT};
	int nextTeam;
	if (sizes[0] != sizes[1])
	{
		// If one team is bigger than the other at the moment,
		// put the first outlier on the smaller team.
		nextTeam = sizes[0] < sizes[1] ? 0 : 1;
	}
	else if (sums[0] != sums[1])
	{
		// If both teams have the same size,
		// put the first outlier on the team with the smaller point sum.
		nextTeam = sums[0] < sums[1] ? 0 : 1;
	}
	else
	{
		// If both teams have the same point sums (incredibly rare),
		// put the first outlier on a random team.
		nextTeam = GetRandomInt(0, 1);
	}
	for (int i = 0; i < sortedPlayers.Length; ++i)
	{
		client = sortedPlayers.Get(i);
		// Skip non-outliers
		if (!g_ClientData[client].isOutlier)
		{
			continue;
		}
		sizes[nextTeam]++;
		g_ClientData[client].isPendingSwap = GetClientTeam(client) != teams[nextTeam];
		nextTeam = (nextTeam + 1) % 2;
	}
}

// Swap as few players as possible.
void SwapFewestPlayers(ArrayList sortedPlayers)
{
	int wrongTeam = 0, correctTeam = 0;
	int teams[2] = {CS_TEAM_T, CS_TEAM_CT};
	int client;
	// Go through the list of players, and increment wrongTeam or correctTeam
	// depending on if the player is already on the correct team or not.
	for (int i = 0; i < sortedPlayers.Length; ++i)
	{
		client = sortedPlayers.Get(i);
		g_ClientData[client].isPendingSwap ? ++wrongTeam : ++correctTeam;
	}
	// Begin swapping players.
	for (int i = 0; i < sortedPlayers.Length; ++i)
	{
		client = sortedPlayers.Get(i);
		// If wrongTeam > correctTeam, swap all players who have ClientData.isPendingSwap = true
		// If correctTeam >= wrongTeam, swap all players who have ClientData.isPendingSwap = false
		if ((wrongTeam > correctTeam) ^ g_ClientData[client].isPendingSwap)
		{
			SAB_SwapPlayer(client, teams[(GetClientTeam(client) + 1) % 2]);
		}
	}
}