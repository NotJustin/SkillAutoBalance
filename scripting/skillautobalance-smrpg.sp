#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <smrpg>
#define REQUIRE_PLUGIN

#define SAB_PLUGIN_VARIANT " SMRPG"

#pragma newdecls required
#pragma semicolon 1

/* Libraries */
bool
	g_UsingAdminmenu,
	g_UsingSMRPG
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
	if (LibraryExists("smrpg"))
	{
		g_UsingSMRPG = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "smrpg"))
	{
		g_UsingSMRPG = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "smrpg"))
	{
		g_UsingSMRPG = false;
	}
}
void GetScore(int client)
{
	g_iClientScore[client] = -1.0;
	if (g_UsingSMRPG)
	{
		g_iClientScore[client] = float(SMRPG_GetClientLevel(client));
		CreateTimer(CHECKSCORE_DELAY, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("SMRPG not found. Must have smrpg plugin running to use this version.");
	}
}
public void SMRPG_OnClientLoaded(int client)
{
	//GetScore(client);
}