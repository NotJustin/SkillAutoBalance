#include <sourcemod>
#include <skillautobalance/core>
#include <adminmenu>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "skillautobalance admin",
	author = "Justin (ff)",
	description = "Adds admin commands to forcibly trigger team balance or change a player's team",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/namenotjustin"
}

// taken straight from basebans.sp :D
enum struct PlayerInfo
{
	int target;
	int targetUserId;
}

PlayerInfo playerinfo[MAXPLAYERS + 1];

bool 
	g_bSetTeamMenuAdded,
	g_bForceBalanceMenuAdded
;

TopMenu hAdminMenu = null;

GlobalForward
	g_AMTeamSelect,
	g_AMClientSelectFail,
	g_BalanceCommandForward,
	g_SetTeamForward
;

public void OnPluginStart()
{
	RegAdminCmd("sm_balance", Command_Balance, ADMFLAG_GENERIC, "Forces a team balance to occur at the end of this round");
	RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_GENERIC, "Set player to CT, T, or SPEC");
	
	g_AMTeamSelect = new GlobalForward("SAB_OnAdminMenuTeamSelect", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_AMClientSelectFail = new GlobalForward("SAB_OnAdminMenuClientSelectFail", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_BalanceCommandForward = new GlobalForward("SAB_OnBalanceCommand", ET_Ignore, Param_Cell);
	g_SetTeamForward = new GlobalForward("SAB_OnSetTeam", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	
	// Used only for FindTarget
	LoadTranslations("common.phrases");
	// Used for admin menu.
	LoadTranslations("sab.phrases");
}

public void OnConfigsExecuted()
{
	// Checks if we have already added the two commands to the admin menu or not, before attempting to add them.
	if (!g_bForceBalanceMenuAdded && !g_bSetTeamMenuAdded && (hAdminMenu = GetAdminTopMenu()) != null)
	{
		AddForceBalanceMenu();
		AddSetTeamMenu();
	}
}

void AddForceBalanceMenu()
{
	TopMenuObject server_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_SERVERCOMMANDS);
	if (server_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	AddToTopMenu(hAdminMenu, "sm_balance", TopMenuObject_Item, AdminMenu_ForceBalance, server_commands, "sm_balance", ADMFLAG_GENERIC);
	g_bForceBalanceMenuAdded = true;
}

void AddSetTeamMenu()
{
	TopMenuObject player_commands = FindTopMenuCategory(hAdminMenu, ADMINMENU_PLAYERCOMMANDS);
	if (player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	AddToTopMenu(hAdminMenu, "sm_setteam", TopMenuObject_Item, AdminMenu_SetTeam, player_commands, "sm_setteam", ADMFLAG_GENERIC);
	g_bSetTeamMenuAdded = true;
}

void AdminMenu_ForceBalance(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Force Balance");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		// Param = the client who used the command.
		ForceBalance(param);
	}
}

void ForceBalance(int client)
{
	SAB_Balance("Force Balance");
	// We pass the client to reply to them about the balance command they just used.
	Call_StartForward(g_BalanceCommandForward);
	Call_PushCell(client);
	Call_Finish();
}

Action Command_Balance(int client, int args)
{
	ForceBalance(client);
	return Plugin_Handled;
}

void AdminMenu_SetTeam(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%t", "Set Player's Team");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplaySetTeamTargetMenu(param);
	}
}

void DisplaySetTeamTargetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SetTeamList);
	char title[100];
	Format(title, sizeof(title), "%t", "Set Player's Team", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	// Adds all players who are in game to the menu.
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	menu.Display(client, MENU_TIME_FOREVER);
}

// Most of this mimics basebans.sp and ban.sp
int MenuHandler_SetTeamList(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hAdminMenu)
	{
		hAdminMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		bool canTarget = CanUserTarget(param1, target);
		// This is an enum that is used to reply to the person who used the command.
		SABMenuSetTeamFailReason reason;
		if (target == 0)
		{
			reason = SAB_MenuSetTeamClientNotFound;
		}
		else if (!canTarget)
		{
			reason = SAB_MenuSetTeamCannotTarget;
		}
		else
		{
			playerinfo[param1].target = target;
			playerinfo[param1].targetUserId = userid;
			DisplayTeamMenu(param1);
		}
		Call_StartForward(g_AMClientSelectFail);
		Call_PushCell(param1);
		Call_PushCell(target);
		Call_PushCell(reason);
		Call_Finish();
	}
}

void DisplayTeamMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TeamList);
	char title[100];
	Format(title, sizeof(title), "%t", "Select Team", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	char item[30];
	Format(item, sizeof(item), "%t", "Spectator", client);
	menu.AddItem("1", item);
	Format(item, sizeof(item), "%t", "Terrorists", client);
	menu.AddItem("2", item);
	Format(item, sizeof(item), "%t", "Counter-Terrorists", client);
	menu.AddItem("3", item);
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_TeamList(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hAdminMenu)
	{
		hAdminMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		char sTeam[32];
		menu.GetItem(param2, sTeam, sizeof(sTeam));
		int team = StringToInt(sTeam);
		PrepareSetTeam(param1, playerinfo[param1].target, team);
	}
}

void PrepareSetTeam(int client, int target, int team)
{
	int originalTarget = GetClientOfUserId(playerinfo[client].targetUserId);
	bool success = true;
	if (originalTarget != target)
	{
		success = false;
	}
	else
	{
		SAB_SwapPlayer(target, team, "Admin Join");
	}
	// This is a forward that can be used to notify the admin
	// that the person they were targetting is no longer in game
	Call_StartForward(g_AMTeamSelect);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(team);
	Call_PushCell(success);
	Call_Finish();
}

Action Command_SetTeam(int client, int args)
{
	SABSetTeamResult result;
	int target = -1;
	if (args < 2)
	{
		result = SAB_SetTeamIncorrectUsage;
	}
	else
	{
		char buff[32];
		GetCmdArg(1, buff, sizeof(buff));
		target = FindTarget(client, buff);
		if (target == -1)
		{
			result = SAB_SetTeamClientNotFound;
		}
		else
		{
			result = SAB_SetTeamSuccess;
			GetCmdArg(2, buff, sizeof(buff));
			if (strcmp(buff, "ct", false) == 0 || strcmp(buff, "3", false) == 0)
			{
				SAB_SwapPlayer(target, CS_TEAM_CT, "Admin Join");
			}
			else if(strcmp(buff, "t", false) == 0 || strcmp(buff, "2", false) == 0)
			{
				SAB_SwapPlayer(target, CS_TEAM_T, "Admin Join");
			}
			else if (strcmp(buff, "spec", false) == 0 || strcmp(buff, "1", false) == 0)
			{
				SAB_SwapPlayer(target, CS_TEAM_SPECTATOR, "Admin Join");
			}
			else
			{
				result = SAB_SetTeamIncorrectUsage;
			}
		}
	}
	// Forward used to notify the admin about the result of their setteam command usage.
	Call_StartForward(g_SetTeamForward);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(result);
	Call_Finish();
	return Plugin_Handled;
}