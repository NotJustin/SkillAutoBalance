/*
 * Вызов рпг меню
 *
 * @param client индекс клиента.
 * @noreturn
 */

native void NCRPG_OpenMenuMain(int client);

/*
 * Вызов хелп меню
 *
 * @param client индекс клиента.
 * @noreturn
 */

native void NCRPG_OpenMenuHelp(int client);

/*
 * Вызов меню статистики
 *
 * @param client индекс клиента.
 * @noreturn
 */

native void NCRPG_OpenMenuStats(int client);

/*
 * Вызов меню статистики других игроков
 *
 * @param client индекс клиента.
 * @noreturn
 */

native void NCRPG_OpenMenuPlayersInfo(int client);

// Help Menu

stock void DisplayHelpMenu(int client, const char[] title)
{
	Handle menu = CreateMenu(HandlerMenuHelpMenu);
	SetMenuTitle(menu, "%T", title, client);
	
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	
	char buffer[32];
	Format(buffer, sizeof(buffer), "%T", "Back", client);
	AddMenuItem(menu, "", buffer);
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	AddMenuItem(menu, "", "", ITEMDRAW_SPACER);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public HandlerMenuHelpMenu(Handle menu, MenuAction action,int client,int param2) {
	if(action == MenuAction_Select)
	{
		NCRPG_OpenMenuHelp(client);
		//DisplayMenu(BuildMenuHelp(client), client, MENU_TIME_FOREVER);
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

/*
 * Вызов меню c игроками
 *
 * @param menu Ссылка на меню.
 * @param client индекс клиента.
 * @param alive жив ли клиент.
 * @return count количество клиентов
 */
 
stock int AddMenuPlayers(Menu menu,int client = 0, bool alive = false) {
	int count;
	char buffer[MAX_NAME_LENGTH+32]; char userid[8];
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(i == client || !IsValidPlayer(i) || (alive && !IsPlayerAlive(i)))
			continue;
		
		IntToString(GetClientUserId(i), userid, sizeof(userid));
		Format(buffer, sizeof(buffer), "%T", "Player", client, userid, i);
		if(menu.AddItem(userid, buffer))
			count++;
	}
	
	return count;
}


stock void SetSafeMenuTitle(Handle menu, const char[] fmt, any:...)
{
	char menuTitle[4096];
	VFormat(menuTitle, sizeof(menuTitle), fmt, 3);
	SetMenuTitle(menu, menuTitle);
}