#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "SkillAutoBalance",
	author = "Justin (ff)",
	description = "A configurable automated team manager",
	version = "3.2.0",
	url = "https://steamcommunity.com/id/NameNotJustin/"
}

/* Libraries */
bool g_UsingAdminmenu;

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

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
}
void GetScore(int client)
{
	float kills, deaths;
	g_iClientScore[client] = -1.0;
	kills = float(GetClientFrags(client));
	deaths = float(GetClientDeaths(client));
	deaths = deaths < 1.0 ? 1.0 : deaths;
	g_iClientScore[client] = kills / deaths;
	if (kills <= 10)
	{
		g_iClientScore[client] = g_iClientScore[client] / 2.0;
	}
	CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}