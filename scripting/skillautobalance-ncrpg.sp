#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <NCIncs/nc_rpg.inc>
#define REQUIRE_PLUGIN

#define SAB_PLUGIN_VARIANT " NCRPG"

#pragma newdecls required
#pragma semicolon 1

/* Libraries */
bool
	g_UsingAdminmenu,
	g_UsingNCRPG
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
	if (LibraryExists("NCRPG"))
	{
		g_UsingNCRPG = true;
	}
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "NCRPG"))
	{
		g_UsingNCRPG = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "NCRPG"))
	{
		g_UsingNCRPG = false;
	}
}
void GetScore(int client)
{
	g_fClientScore[client] = -1.0;
	if (g_UsingNCRPG)
	{
		g_fClientScore[client] = NCRPG_GetSkillSum(client);
		CreateTimer(CHECKSCORE_DELAY, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		LogError("NCRPG not found. Must have NCRPG plugin running to use this version.");
	}
}
public int NCRPG_OnClientLoaded(int client, int count)
{
	//GetScore(client);
}
float NCRPG_GetSkillSum(int client)
{
	float score = 0.0;
	for (int i = 0; i < NCRPG_GetSkillCount(); ++i)
	{
		if (NCRPG_IsValidSkillID(i))
		{
			score += float(NCRPG_GetSkillLevel(client, i));
		}
	}
	return score;
}