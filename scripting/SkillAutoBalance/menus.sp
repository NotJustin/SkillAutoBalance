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
	if (g_iClientForceJoinPreference[client] == 0)
	{
		Format(option1, sizeof(option1), "%t", "Auto-Join T/CT [ENABLED]");
		Format(option2, sizeof(option2), "%t", "Auto-Join Spectator");
		menu.AddItem("0", option1);
		menu.AddItem("1", option2);
	}
	else if (g_iClientForceJoinPreference[client] == 1)
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
		if (StringToInt(menuItem) == 0)
		{
			g_iClientForceJoinPreference[param1] = 0;
		}
		else if (StringToInt(menuItem) == 1)
		{
			g_iClientForceJoinPreference[param1] = 1;
		}
		char sCookieValue[12];
		IntToString(g_iClientForceJoinPreference[param1], sCookieValue, sizeof(sCookieValue));
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
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			ColorPrintToChat(param1, "Client Not Found");
		}
		else if (!CanUserTarget(param1, target))
		{
			ColorPrintToChat(param1, "Cannot Target Player");
		}
		else
		{
			playerinfo[param1].target = target;
			playerinfo[param1].targetUserId = userid;
			DisplayTeamMenu(param1);
		}
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
	if (action == MenuAction_End) delete menu;
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && hTopMenu) hTopMenu.Display(param1, TopMenuPosition_LastCategory);
	else if (action == MenuAction_Select)
	{
		char team[32];
		menu.GetItem(param2, team, sizeof(team));
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
	menu.AddItem("spec", item);
	Format(item, sizeof(item), "%t", "Terrorists", client);
	menu.AddItem("t", item);
	Format(item, sizeof(item), "%t", "Counter-Terrorists", client);
	menu.AddItem("ct", item);
	menu.Display(client, MENU_TIME_FOREVER);
}
void PrepareSetTeam(int client, int target, const char[] team)
{
	int originalTarget = GetClientOfUserId(playerinfo[client].targetUserId);
	if (originalTarget != target)
	{
		if (!client)
		{
			PrefixPrintToServer("Client Not Found");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Client Not Found");
		}
		return;
	}
	ColorPrintToChat(client, "Admin Client Swapped");
	SetTeamFromMenu(target, team);
}
void SetTeamFromMenu(int client, const char[] team)
{
	if (strcmp(team, "ct", false) == 0)
	{
		SwapPlayer(client, TEAM_CT, "Admin Join");
		return;
	}
	else if(strcmp(team, "t", false) == 0)
	{
		SwapPlayer(client, TEAM_T, "Admin Join");
		return;
	}
	SwapPlayer(client, TEAM_SPEC, "Admin Join");
}
void AdminMenu_ForceBalance(TopMenu topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Force Balance");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		g_ForceBalance = true;
		if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(param, "Admin Force Balance");
		}
	}
}