#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <gameme>
#define REQUIRE_PLUGIN

#define SAB_PLUGIN_VARIANT " gameME"

#pragma newdecls required
#pragma semicolon 1

/* Libraries */
bool
	g_UsingAdminmenu,
	g_UsingGameME
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
	if (LibraryExists("gameme"))
	{
		g_UsingGameME = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "gameme"))
	{
		g_UsingGameME = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "gameme"))
	{
		g_UsingGameME = false;
	}
}
void GetScore(int client)
{
	g_iClientScore[client] = -1.0;
	if (g_UsingGameME)
	{
		QueryGameMEStats("playerinfo", client, GameMEStatsCallback, 1);
		CreateTimer(CHECKSCORE_DELAY, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("GameME not found. Must have gameme plugin running to use this version.");
	}
}
Action GameMEStatsCallback(int command, int payload, int client, Handle datapack)
{
	char param[128];
	if (g_iClientScoreUpdated[client])
	{
		return Plugin_Handled;
	}
	g_iClientScoreUpdated[client] = true;
	if (6 <= GetCmdArgs())
	{
		GetCmdArg(6, param, sizeof(param));
		g_iClientScore[client] = StringToFloat(param);
	}
	else
	{
		g_iClientScore[client] = -1.0;
	}
	return Plugin_Handled;
}