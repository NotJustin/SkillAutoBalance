#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <lvl_ranks>
#define REQUIRE_PLUGIN

#define SAB_PLUGIN_VARIANT " Levels Ranks"

#pragma newdecls required
#pragma semicolon 1

/* Libraries */
bool
	g_UsingAdminmenu,
	g_UsingLVLRanks
;

#include "SkillAutoBalance/globals.sp"
#include "SkillAutoBalance/funcs_public.sp"
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
	name = SAB_PLUGIN_NAME,
	author = SAB_PLUGIN_AUTHOR,
	description = SAB_PLUGIN_DESCRIPTION,
	version = SAB_PLUGIN_VERSION,
	url = SAB_PLUGIN_URL
}

void CheckIfLibrariesExist()
{
	if (LibraryExists("adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (LibraryExists("levelsranks"))
	{
		g_UsingLVLRanks = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "levelsranks"))
	{
		g_UsingLVLRanks = true;
		//LR_Hook(LR_OnPlayerLoaded, LR_GetScore);
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "levelranks"))
	{
		g_UsingLVLRanks = false;
	}
}
void GetScore(int client)
{
	g_fClientScore[client] = -1.0;
	if (g_UsingLVLRanks)
	{
		g_fClientScore[client] = float(LR_GetClientInfo(client, ST_EXP));
		CreateTimer(CHECKSCORE_DELAY, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("Level Ranks not found. Must have levelranks plugin running to use this version.");
	}
}

public void LR_GetScore(int iClient, int iAccountID)
{
	//GetScore(iClient);
}
