enum struct PlayerInfo
{
	int target;
	int targetUserId;
}

PlayerInfo playerinfo[MAXPLAYERS + 1];
TopMenu hTopMenu = null;

void CreateForceJoinCookie()
{
	char cookieMenuTitle[100];
	Format(cookieMenuTitle, sizeof(cookieMenuTitle), "%t", "Auto-Join Preference");
	g_hForceSpawn = RegClientCookie("sab_forcespawn", "Auto-Join On Connect", CookieAccess_Private);
	SetCookieMenuItem(Cookie_ForceSpawnPreference, 1, cookieMenuTitle);
}

void Cookie_ForceSpawnPreference(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%t", "Auto-Join Preference");
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		ShowForceJoinMenu(client);
	}
}

void ShowForceJoinMenu(int client)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	Menu menu = new Menu(MenuHandler_ForceJoin);
	char option1[100];
	char option2[100];
	if (g_Players[client].forceJoinPreference == 1)
	{
		Format(option1, sizeof(option1), "%t", "Auto-Join T/CT [ENABLED]");
		Format(option2, sizeof(option2), "%t", "Auto-Join Spectator");
		menu.AddItem("0", option1);
		menu.AddItem("1", option2);
	}
	else if (g_Players[client].forceJoinPreference == 0)
	{
		Format(option1, sizeof(option1), "%t", "Auto-Join T/CT");
		Format(option2, sizeof(option2), "%t", "Auto-Join Spectator [ENABLED]");
		menu.AddItem("0", option1);
		menu.AddItem("1", option2);
	}
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_ForceJoin(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(param2, menuItem, sizeof(menuItem));
		if (!StringToInt(menuItem))
		{
			g_Players[param1].forceJoinPreference = 1;
		}
		else
		{
			g_Players[param1].forceJoinPreference = 0;
		}
		char sCookieValue[12];
		IntToString(g_Players[param1].forceJoinPreference, sCookieValue, sizeof(sCookieValue));
		SetClientCookie(param1, g_hForceSpawn, sCookieValue);
	}
}

void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if(topmenu == hTopMenu || topmenu == null)
	{
		return;
	}
	hTopMenu = topmenu;
}

void AttachSetTeamAdminMenu()
{
	TopMenuObject player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	if(player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "sm_setteam", TopMenuObject_Item, AdminMenu_SetTeam, player_commands, "sm_setteam", ADMFLAG_GENERIC);
	}
}

void AttachForceBalanceAdminMenu()
{
	TopMenuObject server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
	if(server_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "sm_balance", TopMenuObject_Item, AdminMenu_ForceBalance, server_commands, "sm_balance", ADMFLAG_GENERIC);
	}
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

int MenuHandler_SetTeamList(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu)
	{
		hTopMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		target = GetClientOfUserId(userid);
		bool canTarget = CanUserTarget(param1, target);
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

void DisplaySetTeamTargetMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SetTeamList);
	char title[100];
	Format(title, sizeof(title), "%t", "Set Player's Team", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	AddTargetsToMenu2(menu, client, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);
	menu.Display(client, MENU_TIME_FOREVER);
}

int MenuHandler_TeamList(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu)
	{
		hTopMenu.Display(param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		char sTeam[32];
		menu.GetItem(param2, sTeam, sizeof(sTeam));
		int team = StringToInt(sTeam);
		PrepareSetTeam(param1, playerinfo[param1].target, team);
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
		SwapPlayer(target, team, SAB_AdminSetTeam);
	}
	Call_StartForward(g_AMTeamSelect);
	Call_PushCell(client);
	Call_PushCell(target);
	Call_PushCell(team);
	Call_PushCell(success);
	Call_Finish();
}

void AdminMenu_ForceBalance(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Force Balance");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		ForceBalance(param);
	}
}