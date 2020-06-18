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

/* Plugin-Related Functions */

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
	g_iClientScore[client] = -1.0;
	int scoreType = cvar_ScoreType.IntValue;
	float kills, deaths;
	kills = float(GetClientFrags(client));
	deaths = float(GetClientDeaths(client));
	deaths = deaths < 1.0 ? 1.0 : deaths;
	if(scoreType == 0)
	{
		g_iClientScore[client] = kills / deaths;
	}
	else if(scoreType == 1)
	{
		g_iClientScore[client] = kills / deaths + kills / 10.0 - deaths / 20.0;
	}
	else if(scoreType == 2)
	{
		g_iClientScore[client] = kills * kills / deaths;
	}
	if (g_Balancing)
	{
		++g_PlayerCount;
		if (g_PlayerCount == GetClientCountMinusSourceTV())
		{
			BalanceSkill();
			g_PlayerCount = 0;
		}
	}
}