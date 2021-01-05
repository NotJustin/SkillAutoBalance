#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <hlstatsx_api>
#define REQUIRE_PLUGIN

#define SAB_PLUGIN_VARIANT " HLstatsX"

#pragma newdecls required
#pragma semicolon 1

/* Libraries */
bool
	g_UsingAdminmenu,
	g_UsingHLStatsX
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
	if (LibraryExists("hlstatsx_api"))
	{
		g_UsingHLStatsX = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "hlstatsx_api"))
	{
		g_UsingHLStatsX = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "hlstatsx_api"))
	{
		g_UsingHLStatsX = false;
	}
}
void GetScore(int client)
{
	g_fClientScore[client] = -1.0;
	if (g_UsingHLStatsX)
	{
		HLStatsX_Api_GetStats("playerinfo", client, HLStatsXStatsCallback, 0);
		CreateTimer(CHECKSCORE_DELAY, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("HLStatsX not found. Must have hlstatsx_api plugin running to use this version.");
	}
}
void HLStatsXStatsCallback(int command, int payload, int client, DataPack &datapack)
{
	if (client && IsClientInGame(client))
	{
		DataPack pack = view_as<DataPack>(CloneHandle(datapack));
		pack.ReadCell(); // Skipping client rank. Skill is in the next cell
		g_fClientScore[client] = float(pack.ReadCell());
	}
	delete datapack;
}