#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <skillautobalance/core>

#pragma newdecls required
#pragma semicolon 1

#include "SkillAutoBalance/globals.sp"
#include "SkillAutoBalance/functions.sp"
#include "SkillAutoBalance/misc.sp"
#include "SkillAutoBalance/natives.sp"

public Plugin myinfo =
{
	name = SAB_PLUGIN_NAME,
	author = SAB_PLUGIN_AUTHOR,
	description = SAB_PLUGIN_DESCRIPTION,
	version = SAB_PLUGIN_VERSION,
	url = SAB_PLUGIN_URL
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("SAB_Balance", Native_Balance);
	CreateNative("SAB_GetClientScore", Native_GetClientScore);
	CreateNative("SAB_SwapPlayer", Native_SwapPlayer);
	RegPluginLibrary("sab-core");
	return APLRes_Success;
}

public void OnPluginStart()
{
	cvar_AutoTeamBalance = FindConVar("mp_autoteambalance");
	cvar_LimitTeams = FindConVar("mp_limitteams");
	cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	
	cvar_BotsArePlayers = CreateConVar("sab_botsareplayers", "0", "When teams are being balanced, 1 = Bots are players (bots have points/KDR), 0 = Bots are outliers (bots do not have points/KDR)", _, true, 0.0, true, 1.0);
	cvar_KeepPlayersAlive = CreateConVar("sab_keepplayersalive", "1", "Living players are kept alive when their teams are changed", _, true, 0.0, true, 1.0);
	// Not creating a handle for this convar because we are not using it in this plugin.
	CreateConVar("sab_minplayers", "7", "The amount of players not in spectate must be at least this number for a balance to occur", _, true, 3.0);
	cvar_ScoreType = CreateConVar("sab_scoretype", "0", "0 = Auto detect scoretype. Only change this if you have multiple types loaded. 1 = gameME, 2 = HLstatsX, 3 = Kento-RankMe, 4 = LevelsRanks, 5 = NCRPG, 6 = kpr_rating, 7 = SMRPG", _, true, 0.0, true, 7.0);
	
	cvar_AutoTeamBalance.AddChangeHook(UpdateAutoTeamBalance);
	cvar_LimitTeams.AddChangeHook(UpdateLimitTeams);
	cvar_ScoreType.AddChangeHook(UpdateScoreType);
	
	g_BalanceForward = new GlobalForward("SAB_OnSkillBalance", ET_Ignore, Param_CellByRef, Param_String);
	g_PacifyForward = new GlobalForward("SAB_OnClientPacified", ET_Ignore, Param_Cell);
	g_SwapForward = new GlobalForward("SAB_OnClientTeamChanged", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	
	HookEvent("round_end", Event_RoundEnd);

	AutoExecConfig(true, "sab-core");
}

public void OnLibraryAdded(const char[] name)
{
	// If we automatically set scoretype and haven't found one yet, find one now.
	if (g_ScoreType == ScoreType_Invalid && view_as<SABScoreType>(cvar_ScoreType.IntValue) == ScoreType_Auto)
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
		else if (StrEqual(name, "kpr_rating"))
		{
			g_ScoreType = ScoreType_KPRRating;
		}
		else if (StrEqual(name, "smrpg"))
		{
			g_ScoreType = ScoreType_SMRPG;
		}
	}
}
public void OnLibraryRemoved(const char[] name)
{
	// We are not going to check if someone unloaded their scoretype while they removed automatic scoretype detection.
	if (g_ScoreType == ScoreType_Invalid || view_as<SABScoreType>(cvar_ScoreType.IntValue) != ScoreType_Auto)
	{
		return;
	}
	// We automatically set scoretype, so check if one has unloaded.
	if (StrEqual(name, "gameme")
	|| StrEqual(name, "hlstatsx_api")
	|| StrEqual(name, "kento_rankme")
	|| StrEqual(name, "levelsranks")
	|| StrEqual(name, "NCRPG")
	|| StrEqual(name, "kpr_rating")
	|| StrEqual(name, "smrpg"))
	{
		// If it has unloaded, find a new scoretype to use.
		SABScoreType scoreType = FindScoreType();
		if (scoreType == ScoreType_Invalid)
		{
			g_ScoreType = scoreType;
		}
		else
		{
			LogError("Last scoretype was unloaded, and no replacement is currently loaded");
		}
	}
}

public void OnConfigsExecuted()
{
	// This bool is needed to make sure the scoretype is only updated after all plugins are loaded.
	g_bConfigsExecuted = true;
	// This plugin handles teams. We make sure to always disable mp_autoteambalance and mp_limitteams
	cvar_AutoTeamBalance.SetInt(0);
	cvar_LimitTeams.SetInt(0);
	UpdateScoreType(cvar_ScoreType, "", "");
}

// When a client joins the server, reset them.
public void OnClientPostAdminCheck(int client)
{
	g_ClientData[client].Reset();
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (!g_ClientData[client].isPassive)
	{
		return Plugin_Continue;
	}
	// If a client is passive, prevent them from attacking.
	// This only happens to players at round end if they are alive while their team is changed.
	buttons &= ~IN_ATTACK2;
	buttons &= ~IN_ATTACK;
	return Plugin_Changed;
}

// At the end of every round, update scores and check if balance is needed.
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	UpdateScores();
	CreateTimer(1.0, Timer_DelayBalance);
}

void UpdateAutoTeamBalance(ConVar convar, char[] oldValue, char[] newValue)
{
	convar.IntValue = 0;
}

void UpdateLimitTeams(ConVar convar, char[] oldValue, char[] newValue)
{
	convar.IntValue = 0;
}

void UpdateScoreType(ConVar convar, char[] oldValue, char[] newValue)
{
	if (!g_bConfigsExecuted)
	{
		return;
	}
	SABScoreType scoreType = view_as<SABScoreType>(convar.IntValue);
	switch(scoreType)
	{
		// The default scoretype is auto. We use FindScoreType to check which scoretype is loaded, and use that one.
		// Otherwise, we check if the scoretype set in the config is loaded and log error if it is not (in DoesScoreTypeExist)
		case ScoreType_Auto:
		{
			scoreType = FindScoreType();
			if (scoreType != ScoreType_Invalid)
			{
				g_ScoreType = scoreType;
			}
			else
			{
				LogError("There are no scoretypes loaded on server.");
			}
		}
		case ScoreType_gameME:
		{
			DoesScoreTypeExist("gameme", scoreType);
		}
		case ScoreType_HLstatsX:
		{
			DoesScoreTypeExist("hlstatsx_api", scoreType);
		}
		case ScoreType_KentoRankMe:
		{
			DoesScoreTypeExist("kento_rankme", scoreType);
		}
		case ScoreType_LevelsRanks:
		{
			DoesScoreTypeExist("levelsranks", scoreType);
		}
		case ScoreType_NCRPG:
		{
			DoesScoreTypeExist("NCRPG", scoreType);
		}
		case ScoreType_KPRRating:
		{
			DoesScoreTypeExist("kpr_rating", scoreType);
		}
		case ScoreType_SMRPG:
		{
			DoesScoreTypeExist("smrpg", scoreType);
		}
	}
}