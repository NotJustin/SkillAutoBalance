#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <gameme>
#include <kento_rankme/rankme>
#include <lvl_ranks>
#include <NCIncs/nc_rpg.inc>
#include <smrpg>
#include <hlstatsx_api>
#define REQUIRE_PLUGIN

#pragma newdecls required
#pragma semicolon 1

#include "SkillAutoBalance/globals.sp"
#include "SkillAutoBalance/colors.sp"
#include "SkillAutoBalance/convars.sp"
#include "SkillAutoBalance/commands.sp"
#include "SkillAutoBalance/configs.sp"
#include "SkillAutoBalance/events.sp"
#include "SkillAutoBalance/funcs_balance.sp"
#include "SkillAutoBalance/funcs_client.sp"
#include "SkillAutoBalance/funcs_misc.sp"
#include "SkillAutoBalance/funcs_team.sp"
#include "SkillAutoBalance/menus.sp"
#include "SkillAutoBalance/timers.sp"

public Plugin myinfo =
{
	name = "SkillAutoBalance",
	author = "Justin (ff)",
	description = "A configurable automated team manager",
	version = "3.2.0",
	url = "https://steamcommunity.com/id/NameNotJustin/"
}

/* Plugin-Related Functions */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_LateLoad = late;
	return APLRes_Success;
}
public void OnPluginStart()
{
	InitColorStringMap();
	CreateConVars();
	AddChangeHooks();
	HookEvents();
	RegCommands();

	AddCommandListener(CommandList_JoinTeam, "jointeam");

	AutoExecConfig(true, "SkillAutoBalance");

	LoadTranslations("skillautobalance.phrases");
	LoadTranslations("common.phrases");

	CreateForceJoinCookie();

	if (g_LateLoad)
	{
		OnConfigsExecuted();
		for (int i = 0; i < MaxClients; ++i)
		{
			if (IsClientInGame(g_iClient[i]))
			{
				g_iClientTeam[i] = GetClientTeam(g_iClient[i]);
			}
		}	
	}
}
public void OnConfigsExecuted()
{
	UpdateConfigs();
}
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gameme"))
	{
		g_UsingGameME = true;
	}
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "kento_rankme"))
	{
		g_UsingRankME = true;
	}
	if (StrEqual(name, "levelranks"))
	{
		g_UsingLVLRanks = true;
	}
	if (StrEqual(name, "NCRPG"))
	{
		g_UsingNCRPG = true;
	}
	if (StrEqual(name, "smrpg"))
	{
		g_UsingSMRPG = true;
	}
	if (StrEqual(name, "hlstatsx_api"))
	{
		g_UsingHLStatsX = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gameme"))
	{
		g_UsingGameME = false;
	}
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "kento_rankme"))
	{
		g_UsingRankME = false;
	}
	if (StrEqual(name, "levelranks"))
	{
		g_UsingLVLRanks = false;
	}
	if (StrEqual(name, "NCRPG"))
	{
		g_UsingNCRPG = false;
	}
	if (StrEqual(name, "smrpg"))
	{
		g_UsingSMRPG = false;
	}
	if (StrEqual(name, "hlstatsx_api"))
	{
		g_UsingHLStatsX = false;
	}
}

/* Public Map-Related Functions */
public void OnMapStart()
{
	g_AllowSpawn = true;
	g_MapLoaded = true;
	g_PlayerCount = 0;
	g_PlayerCountChange = 0;
	g_RoundCount = 0;
	if (cvar_TeamMenu.BoolValue)
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
	}
	else
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
	}
	g_iStreak[0] = 0.0;
	g_iStreak[1] = 0.0;
}
public void OnMapEnd()
{
	g_MapLoaded = false;
}

/* Public Client-Related Functions */
public void OnClientCookiesCached(int client)
{
	char buffer[24];
	GetClientCookie(client, g_hForceSpawn, buffer, sizeof(buffer));
	if (strlen(buffer) > 0)
	{
		g_iClientForceJoinPreference[client] = StringToInt(buffer);
	}
}
public void OnClientDisconnect(int client)
{
	g_iClientTeam[client] = TEAM_SPEC;
	g_iClientScore[client] = -1.0;
	g_iClientFrozen[client] = false;
	g_iClientOutlier[client] = false;
	++g_PlayerCountChange;
	if (!AreTeamsEmpty())
	{
		return;
	}
	g_AllowSpawn = true;
}
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (g_iClientFrozen[client])
	{
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}