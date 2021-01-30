#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <skillautobalance>
#include <sab_rating>

#pragma newdecls required
#pragma semicolon 1

/* Libraries */
bool g_UsingAdminmenu;

#include "SkillAutoBalance/globals.sp"
#include "SkillAutoBalance/convars.sp"
#include "SkillAutoBalance/forwards.sp"
#include "SkillAutoBalance/libraries.sp"
#include "SkillAutoBalance/funcs_public.sp"
#include "SkillAutoBalance/commands.sp"
#include "SkillAutoBalance/configs.sp"
#include "SkillAutoBalance/events.sp"
#include "SkillAutoBalance/funcs_afkmanager.sp"
#include "SkillAutoBalance/funcs_gameme.sp"
#include "SkillAutoBalance/funcs_hlstatsx.sp"
#include "SkillAutoBalance/funcs_ncrpg.sp"
#include "SkillAutoBalance/funcs_client.sp"
#include "SkillAutoBalance/funcs_balance.sp"
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