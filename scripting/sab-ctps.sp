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
	AssignPlayersToTeams(sortedPlayers, outliers, sizes);
	if (outliers > 0)
	{
		AssignOutliersToTeams(sortedPlayers, sizes);
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
		if (IsFakeClient(client) && !cvar_BotsArePlayers.BoolValue)
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
void AssignPlayersToTeams(ArrayList sortedPlayers, int outliers, int sizes[2])
{
	int client;
	int i = -1;
	int totalSize = sortedPlayers.Length - outliers;
	int smallTeamSize = totalSize / 2;
	int bigTeamSize = totalSize % 2 == 0 ? smallTeamSize : smallTeamSize + 1;
	float tSum = 0.0;
	float ctSum = 0.0;
	// Assigns players to teams until one of the teams reaches the maximum team size.
	// This is necessary, to avoid uneven team sizes. We want 5v5 or 5v6, not 4v6 or 4v7.
	while(sizes[0] < bigTeamSize && sizes[1] < bigTeamSize)
	{
		++i;
		client = sortedPlayers.Get(i);
		// Skip outliers
		if (g_ClientData[client].isOutlier)
		{
			continue;
		}
		// Check which team we want to put this client on, and check if they're already on that team.
		if (tSum < ctSum)
		{
			tSum += SAB_GetClientScore(client);
			++sizes[0];
			g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_CT;
		}
		else
		{
			ctSum += SAB_GetClientScore(client);
			++sizes[1];
			g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_T;
		}
	}
	// Once one team has reached the maximum team size, dump the remaining players onto the other team.
	// Usually this loop will only occur once.
	for(int j = i; j < sortedPlayers.Length; ++j)
	{
		client = sortedPlayers.Get(j);
		// Skip outliers
		if (g_ClientData[client].isOutlier)
		{
			continue;
		}
		// Check which team we want to put this client on, and check if they're already on that team.
		if (sizes[0] < smallTeamSize)
		{
			++sizes[0];
			g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_CT;
		}
		else
		{
			++sizes[1];
			g_ClientData[client].isPendingSwap = GetClientTeam(client) == CS_TEAM_T;
		}
	}
}

// After rearranging teams, check if the outlier-players need their teams to be changed.
void AssignOutliersToTeams(ArrayList sortedPlayers, int sizes[2])
{
	int client;
	int teams[2] = {CS_TEAM_T, CS_TEAM_CT};
	int nextTeam = (sizes[0] <= sizes[1] ? 0 : 1);
	for (int i = 0; i < sortedPlayers.Length; ++i)
	{
		client = sortedPlayers.Get(i);
		// Skip non-outliers
		if (!g_ClientData[client].isOutlier)
		{
			continue;
		}
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