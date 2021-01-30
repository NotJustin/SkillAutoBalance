#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <skillautobalance>
#include <skillautobalance-rating>

#define BALANCE_CACHE_SIZE 2

public Plugin myinfo =
{
	name = "skillautobalance rating",
	author = SAB_PLUGIN_AUTHOR,
	description = "A method of rating players based on their kills per round",
	version = "1.0.0",
	url = SAB_PLUGIN_URL
}

ConVar cvar_GraceTime;

bool g_bClientSpawned[MAXPLAYERS + 1];

int 
	g_iClientKillsThisRound[MAXPLAYERS + 1],
	g_iClientRounds[MAXPLAYERS + 1],
	g_iClientStartingTeam[MAXPLAYERS + 1],
	g_iClientBalanceIndex[MAXPLAYERS + 1]
;

float
	g_fClientKPR[MAXPLAYERS + 1][BALANCE_CACHE_SIZE],
	g_fClientScore[MAXPLAYERS + 1]
;

char g_Path[PLATFORM_MAX_PATH];

public APLRes AskPluginLoad2(Handle myself, bool late, char [] error, int err_max)
{
	CreateNative("SAB_GetScore", Native_GetScore);
	RegPluginLibrary("sabrating");
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		for (int balanceIndex = 0; balanceIndex < BALANCE_CACHE_SIZE; ++balanceIndex)
		{
			g_fClientKPR[client][balanceIndex] = -1.0;
		}
	}
}
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, CheckIfClientSpawned, event.GetInt("userid"));
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim && victim <= MaxClients && IsClientInGame(victim) && attacker && attacker <= MaxClients && IsClientInGame(attacker))
	{
		++g_iClientKillsThisRound[attacker];
	}
}
Action CheckIfClientSpawned(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (!IsWarmupActive() && client > 0 && client <= MaxClients && IsClientInGame(client) && !g_bClientSpawned[client] && IsPlayerAlive(client))
	{
		g_bClientSpawned[client] = true;
		++g_iClientRounds[client];
	}
	return Plugin_Handled;
}
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	float time = cvar_GraceTime.FloatValue < 0.2 ? 0.2 : cvar_GraceTime.FloatValue;
	CreateTimer(time, Timer_GraceTimeOver);
	for(int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client))
		{
			g_bClientSpawned[client] = false;
			g_iClientKillsThisRound[client] = 0;
			g_iClientStartingTeam[client] = GetClientTeam(client);
		}
	}
}
public void SAB_OnSkillBalance(SABReason &reason)
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		g_iClientBalanceIndex[client] = (g_iClientBalanceIndex[client] + 1) % BALANCE_CACHE_SIZE;
		g_fClientKPR[client][g_iClientBalanceIndex[client]] = -1.0;
		g_iClientRounds[client] = 0;
	}
}
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!IsWarmupActive())
	{
		for(int client = 1; client <= MaxClients; ++client)
		{
			if (IsClientInGame(client))
			{
				if (g_iClientRounds[client] > 0)
				{
					g_fClientKPR[client][g_iClientBalanceIndex[client]] = ((g_iClientRounds[client] - 1) * g_fClientKPR[client][g_iClientBalanceIndex[client]] + g_iClientKillsThisRound[client]) / g_iClientRounds[client];
					UpdateScore(client);
				}
			}
		}
	}
}
bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}
void UpdateScore(int client)
{
	float kprSum = 0.0;
	int startingIndex = (g_iClientBalanceIndex[client] + 1) % BALANCE_CACHE_SIZE;
	int index = startingIndex;
	int multiplier = 1;
	int multiplierSum = 0;
	do
	{
		if (g_fClientKPR[client][index] != -1)
		{
			kprSum += multiplier * g_fClientKPR[client][index];
			multiplierSum += multiplier
		}
		++multiplier;
		index = (index + 1) % BALANCE_CACHE_SIZE;
	}
	while(index != startingIndex);
	g_fClientScore[client] = kprSum / multiplierSum;
}

public any Native_GetScore(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	return g_fClientScore[client];
}