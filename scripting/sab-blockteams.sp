#include <sourcemod>
#include <skillautobalance/core>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#tryinclude <afk_manager>
#define REQUIRE_PLUGIN

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "skillautobalance blockteams",
	author = "Justin (ff)",
	description = "Adds the option to auto assign clients to teams and prevent them from switching.",
	version = "1.0.0",
	url = "https://steamcommunity.com/id/namenotjustin"
}

enum struct SABClientData
{
	int team;
	int forceJoinPreference;
	
	bool pendingForceJoin;
	bool postAdminChecked;
	bool pendingSwap;
	bool fullyConnected;
	
	void Reset()
	{
		this.team = CS_TEAM_SPECTATOR;
		this.forceJoinPreference = 1;
		this.pendingForceJoin = false;
	}
}

SABClientData g_ClientData[MAXPLAYERS + 1];

bool 
	g_bAllowSpawn = true,
	g_bLateLoad,
	g_bMapLoaded
;

// Existing convars
ConVar
	cvar_GraceTime,
	cvar_MinPlayers // It comes from skillautobalance
;

// Custom convars
ConVar
	cvar_BlockTeamSwitch,
	cvar_ChatChangeTeam,
	cvar_EnablePlayerTeamMessage,
	cvar_ForceJoinTeam,
	cvar_MaxTeamSize,
	cvar_TeamMenu
;

Handle g_hForceSpawn;

GlobalForward
	g_AFKReturnForward,
	g_ClientInitializedForward,
	g_ClientKickForward,
	g_JoinForward,
	g_JoinTeamForward
;

public void OnPluginStart()
{
	LoadTranslations("sab.phrases");
	// Existing convars
	cvar_GraceTime = FindConVar("mp_join_grace_time");
	
	// Custom convars
	cvar_BlockTeamSwitch = CreateConVar("sab_blockteamswitch", "0", "0 = Don't block. 1 = Block, can join spectate, must rejoin same team. 2 = Block completely (also disables teammenu and chatchangeteam commands like !join !spec)", _, true, 0.0, true, 2.0);
	cvar_ChatChangeTeam = CreateConVar("sab_chatchangeteam", "0", "Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)", _, true, 0.0, true, 1.0);
	cvar_EnablePlayerTeamMessage = CreateConVar("sab_enableplayerteammessage", "0", "Show the messages in chat when a player switches team?", _, true, 0.0, true, 1.0);
	cvar_ForceJoinTeam = CreateConVar("sab_forcejointeam", "0", "0 = Disabled, 1 = Optional (!settings), 2 = Forced. Force clients to join a team upon connecting to the server. Always enabled if both sab_chatchangeteam and sab_teammenu are disabled", _, true, 0.0, true, 2.0);
	cvar_MaxTeamSize = CreateConVar("sab_maxteamsize", "0", "0 = Unlimited. Max players allowed on each team. If both teams reach this amount, new non-admin players are kicked. Only works if sab_blockteamswitch is 2.", _, true, 0.0);
	cvar_TeamMenu = CreateConVar("sab_teammenu", "1", "Whether to enable or disable the join team menu.", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sab-blockteams");
	
	cvar_BlockTeamSwitch.AddChangeHook(UpdateBlockTeamSwitch);
	cvar_TeamMenu.AddChangeHook(UpdateTeamMenu);
	
	HookEvent("player_connect_full", Event_PlayerConnectFull);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_connect", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	
	RegConsoleCmd("sm_j", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_s", Command_Spectate, "Switches player to spectator team");
	
	AddCommandListener(CommandList_JoinTeam, "jointeam");
	AddCommandListener(CommandList_JoinTeam, "spectate");
	
	CreateForceJoinCookie();
	
	g_AFKReturnForward = new GlobalForward("SAB_OnClientAFKReturn", ET_Ignore, Param_Cell);
	g_ClientInitializedForward = new GlobalForward("SAB_OnClientInitialized", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_ClientKickForward = new GlobalForward("SAB_OnClientKick", ET_Ignore, Param_Cell, Param_Cell);
	g_JoinForward = new GlobalForward("SAB_OnClientJoinCommand", ET_Ignore, Param_Cell, Param_Cell);
	g_JoinTeamForward = new GlobalForward("SAB_OnClientJoinTeam", ET_Ignore, Param_Cell, Param_Cell);
	
	if (g_bLateLoad)
	{
		for (int client = 1; client <= MaxClients; ++client)
		{
			if (!IsClientInGame(client) || IsClientSourceTV(client))
			{
				continue;
			}
			// Caching client team so that if they are allowed to move to spectate, we can
			// try to force them to rejoin the same team when they are ready to join a team again.
			g_ClientData[client].team = GetClientTeam(client);
			if (AreClientCookiesCached(client))
			{
				OnClientCookiesCached(client);
			}
		}
	}
}

public void OnConfigsExecuted()
{
	// After all plugins are loaded, find this convar (from skillautobalance)
	cvar_MinPlayers = FindConVar("sab_minplayers");
	
	UpdateTeamMenu(cvar_TeamMenu, "", "");
	UpdateBlockTeamSwitch(cvar_BlockTeamSwitch, "", "");
}

void UpdateBlockTeamSwitch(ConVar convar, char [] oldValue, char [] newValue)
{
	// We cannot modify gamerules until after the map is loaded
	if (!g_bMapLoaded)
	{
		return;
	}
	// If we completely block changing teams, we disable the team menu.
	if (convar.IntValue == 2)
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
		return;
	}
	// Otherwise, check if we need to reenable the teammenu.
	UpdateTeamMenu(cvar_TeamMenu, oldValue, newValue);
}

void UpdateTeamMenu(ConVar convar, char[] oldValue, char[] newValue)
{
	// We cannot modify gamerules until after the map is loaded
	if (!g_bMapLoaded)
	{
		return;
	}
	if (!convar.BoolValue)
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
		return;
	}
	GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
}

public void OnMapStart()
{
	// On map start, allow spawning (this corresponds to mp_join_grace_period)
	// It must be true at map start and when the server is empty, in order to allow
	// the first person to join the server to spawn.
	// It is also only relevant if sab_blockteamswitch is 1 or 2.
	g_bAllowSpawn = true;
	g_bMapLoaded = true;
	// Disable the team menu on map start.
	GameRules_SetProp("m_bIsQueuedMatchmaking", cvar_TeamMenu.IntValue);
}

public void OnMapEnd()
{
	g_bMapLoaded = false;
}

// When cookies are cached, set the client's force join prefrence
// Only relevant for sab_forcejointeam 1
public void OnClientCookiesCached(int client)
{
	char buffer[24];
	GetClientCookie(client, g_hForceSpawn, buffer, sizeof(buffer));
	g_ClientData[client].forceJoinPreference = strlen(buffer) > 0 ? StringToInt(buffer) : 0;
}

public void OnClientPostAdminCheck(int client)
{
	// Check if teams are "full". This is only relevant if sab_maxteamsize is set.
	// This will enforce a team size limit, while allowing admins to join the server.
	// The admins will only be allowed to spectate.
	// Exception is if they set their own team by the skillautobalance-admin plugin.
	if (AreTeamsFull())
	{
		bool admin = CheckCommandAccess(client, "", ADMFLAG_GENERIC, true);
		Call_StartForward(g_ClientKickForward);
		Call_PushCell(client);
		Call_PushCell(admin);
		Call_Finish();
		if (!admin)
		{
			CreateTimer(0.1, Timer_KickClient, GetClientUserId(client));
			return;
		}
	}
	g_ClientData[client].postAdminChecked = true;
	if (g_ClientData[client].fullyConnected)
	{
		// Initialize client only after we have ensured that they are both
		// fully connected and are not going to be kicked.
		InitializeClient(client);
	}
}

public void OnClientDisconnect(int client)
{
	// Reset the booleans we use to check if we should initialize this client index
	g_ClientData[client].postAdminChecked = false;
	g_ClientData[client].fullyConnected = false;
	if (!AreTeamsEmpty())
	{
		return;
	}
	// If teams are empty, we need to enable spawning.
	g_bAllowSpawn = true;
}

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	event.BroadcastDisabled = !cvar_EnablePlayerTeamMessage.BoolValue;
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	if (team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		// Whenever the client's team changes to T or CT, cache that team.
		g_ClientData[client].team = team;
	}
}

void Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_ClientData[client].fullyConnected = true;
	if (g_ClientData[client].postAdminChecked)
	{
		// Initialize client only after we have ensured that they are both
		// fully connected and are not going to be kicked.
		InitializeClient(client);
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// At round end, prevent spawning.
	g_bAllowSpawn = false;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (IsWarmupActive())
	{
		// Always allow spawning during warmup.
		g_bAllowSpawn = true;
		return;
	}
	if (cvar_GraceTime.BoolValue)
	{
		// Allow spawning during mp_join_grace_period.
		g_bAllowSpawn = true;
		CreateTimer(cvar_GraceTime.FloatValue, Timer_GraceTimeOver, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Command_Join(int client, int args)
{
	int team;
	bool success = true;
	// When the join command is used, we verify that the client is allowed to join a team before automatically putting them on a team.
	if (AreTeamsFull() || client == 0 || !cvar_ChatChangeTeam.BoolValue || cvar_BlockTeamSwitch.IntValue == 2 || (team = GetClientTeam(client)) == CS_TEAM_T || team == CS_TEAM_CT)
	{
		success = false;
	}
	else
	{
		PutClientOnATeam(client);
	}
	// This forward is used to notify the client whether they have successfully joined a team or not.
	Call_StartForward(g_JoinForward);
	Call_PushCell(client);
	Call_PushCell(success);
	Call_Finish();
	return Plugin_Handled;
}

Action Command_Spectate(int client, int args)
{
	// When the spectate command is used, we verify that the client is allowed to switch teams before moving them.
	if (client == 0 || !cvar_ChatChangeTeam.BoolValue || cvar_BlockTeamSwitch.IntValue == 2 || GetClientTeam(client) == CS_TEAM_SPECTATOR)
	{
		return Plugin_Handled;
	}
	// If they are alive, kill them before changing their team.
	// The purpose of this is to trigger round_end if this person is the last alive on a team.
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	return Plugin_Handled;
}

void PutClientOnATeam(int client)
{
	// If their team isn't cached, we put the client on the smallest team.
	if (g_ClientData[client].team == CS_TEAM_SPECTATOR || g_ClientData[client].team == CS_TEAM_NONE)
	{
		SAB_SwapPlayer(client, GetSmallestTeam(), "Auto Join");
		return;
	}
	// If their team is cached, try to put them on their previous team. Otherwise, put them on the other team.
	int teams[2] = {CS_TEAM_T, CS_TEAM_CT};
	int otherTeam = (g_ClientData[client].team + 1) % 2;
	int teamToJoin = CanJoin(client, g_ClientData[client].team) ? g_ClientData[client].team : teams[otherTeam];
	SAB_SwapPlayer(client, teamToJoin, "Auto Join");
}

/* Command Listeners */
Action CommandList_JoinTeam(int client, const char[] command, int argc)
{
	// If the map is not yet loaded, ignore any 'jointeam' commands. Not sure if this could ever actually happen.
	if (!g_bMapLoaded)
	{
		return Plugin_Stop;
	}
	// When the client tries to change team, check if it is allowed.
	if (cvar_BlockTeamSwitch.IntValue == 0)
	{
		return Plugin_Continue;
	}
	// If there are less players on team than the minimum, do not block team switching.
	// If cvar_MinPlayers is null, there is some other issue going on entirely (FindConVar failed on sab_minplayers somehow?)
	if (cvar_MinPlayers != null && (GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT)) < cvar_MinPlayers.IntValue)
	{
		return Plugin_Continue;
	}
	// If it is not allowed, allow it anyway if we are forcing them to join a team ourselves.
	if (g_ClientData[client].pendingForceJoin)
	{
		g_ClientData[client].pendingForceJoin = false;
		return Plugin_Continue;
	}
	// If we aren't forcing them on a team and we completely block changing teams, do not allow them to change team.
	if (cvar_BlockTeamSwitch.IntValue == 2)
	{
		return Plugin_Stop;
	}
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	int team = StringToInt(arg);
	// If they are trying to join UNASSIGNED somehow, prevent it.
	if (team == CS_TEAM_NONE)
	{
		return Plugin_Stop;
	}
	// If they are trying to join spectator, always allow it.
	if (team == CS_TEAM_SPECTATOR)
	{
		return Plugin_Continue;
	}
	SABJoinTeamResult result;
	// Otherwise, check if they can join the team they are trying to join before proceeding.
	if ((result = CanJoin(client, team)) != SAB_JoinTeamSuccess)
	{
		Call_StartForward(g_JoinTeamForward);
		Call_PushCell(client);
		Call_PushCell(result);
		Call_Finish();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

void InitializeClient(int client)
{
	bool teamMenuEnabled = cvar_TeamMenu.BoolValue;
	bool autoJoin = false;
	bool autoJoinSuccess = false;
	int forceJoin = cvar_ForceJoinTeam.IntValue;
	// Check if we must force clients to join a team.
	bool mustForceJoin = (forceJoin == 2 || (!cvar_ChatChangeTeam.BoolValue && !teamMenuEnabled));
	// If we are not forcing clients to join a team,
	// check if this client wants to be forced on a team.
	if (!mustForceJoin && (forceJoin == 0 || g_ClientData[client].forceJoinPreference == 2))
	{
		return;
	}
	autoJoin = true;
	// If the teams aren't full, force the client to join a team.
	if (!AreTeamsFull())
	{
		// Prepare to switch the client's team by ClientCommand.
		// Taken from SM9's Auto Assign Team plugin https://forums.alliedmods.net/showthread.php?t=321314
		g_ClientData[client].pendingForceJoin = true;
		int team = GetSmallestTeam();
		ClientCommand(client, "jointeam 0 %i", team);
		// Respawn the player if spawning is allowed.
		if (!IsPlayerAlive(client) && ((team = GetClientTeam(client)) == CS_TEAM_T || team == CS_TEAM_CT) && (g_bAllowSpawn || AreTeamsEmpty()))
		{
			CS_RespawnPlayer(client);
		}
		autoJoinSuccess = true;
	}
	else
	{
		// Only admins will get here. If teams are full, force the admin to join spectator.
		ClientCommand(client, "spectate");
	}
	// Forward used to notify the client that they've been forced to join a team.
	Call_StartForward(g_ClientInitializedForward);
	Call_PushCell(client);
	Call_PushCell(teamMenuEnabled);
	Call_PushCell(autoJoin);
	Call_PushCell(autoJoinSuccess);
	Call_Finish();
}

// If both terrorist and counter-terrorist teams have 0 players, teams are empty.
bool AreTeamsEmpty()
{
	return !(GetTeamClientCount(CS_TEAM_T) + GetTeamClientCount(CS_TEAM_CT));
}

bool AreTeamsFull()
{
	// Players are allowed to switch to spectate if they want.
	if (cvar_BlockTeamSwitch.IntValue != 2)
	{
		return false;
	}
	// There is only one player on server.
	if (GetClientCount(true) <= 1)
	{
		return false;
	}
	// We do not a maximum team size.
	if (!cvar_MaxTeamSize.BoolValue)
	{
		return false;
	}
	// We have a maximum team size, but one of the teams has not reached that size.
	if (GetTeamClientCount(CS_TEAM_T) != cvar_MaxTeamSize.IntValue || GetTeamClientCount(CS_TEAM_CT) != cvar_MaxTeamSize.IntValue)
	{
		return false;
	}
	// Both teams are full.
	return true;
}

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
	Format(option1, sizeof(option1), "%t", "Auto-Join T/CT");
	Format(option2, sizeof(option2), "%t", "Auto-Join Spectator");
	// Append the word "ENABLED" to whichever option is currently active.
	g_ClientData[client].forceJoinPreference == 2 ? StrCat(option1, sizeof(option1), " [ENABLED]") : StrCat(option2, sizeof(option2), " [ENABLED]");
	menu.AddItem("1", option1);
	menu.AddItem("2", option2);
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
		g_ClientData[param1].forceJoinPreference = StringToInt(menuItem);
		SetClientCookie(param1, g_hForceSpawn, menuItem); // Assumption here is that GetItem and StringToInt both will never fail.
	}
}

Action Timer_GraceTimeOver(Handle timer)
{
	g_bAllowSpawn = false;
	return Plugin_Handled;
}

SABJoinTeamResult CanJoin(int client, int team)
{
	// Store team client counts in abstract way to save lines.
	int count[2];
	count[0] = GetTeamClientCount(CS_TEAM_T);
	count[1] = GetTeamClientCount(CS_TEAM_CT);
	int newTeamCount = count[team - 2];
	int otherTeamCount = count[(team + 1) % 2];
	// If the team the client wants to join has more players than the other, do not allow the client to join.
	if (newTeamCount > otherTeamCount)
	{
		return SAB_NewTeamHasMorePlayers;
	}
	// If both team sizes are the same and the client wants to join their previous team, allow it.
	if (newTeamCount == otherTeamCount && g_ClientData[client].team == team)
	{
		return SAB_JoinTeamSuccess;
	}
	// If the team the client wants to join has fewer players than the other, allow it only if the client isn't already on a team.
	int currentTeam = GetClientTeam(client);
	if (newTeamCount < otherTeamCount && currentTeam != CS_TEAM_T && currentTeam != CS_TEAM_CT)
	{
		return SAB_JoinTeamSuccess;
	}
	// Otherwise, they are trying to switch to the other team and we will not allow it.
	return SAB_MustJoinPreviousTeam;
}

// Checks which team has the fewest players, or picks a random team.
int GetSmallestTeam()
{
	int tSize = GetTeamClientCount(CS_TEAM_T);
	int ctSize = GetTeamClientCount(CS_TEAM_CT);
	return tSize == ctSize ? GetRandomInt(CS_TEAM_T, CS_TEAM_CT) : tSize < ctSize ? CS_TEAM_T : CS_TEAM_CT;
}

bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

// Delays kicking the client (just copying what reserved slots does).
Action Timer_KickClient(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	KickClient(client, "%t", "Kicked Because Teams Full");
}

// If afk-manager4 is being used, and sab_blockteamswitch == 2, then an issue may occur sometimes.
// A client who is afk will be moved to spectate, and they will not have a way to return from spectate.
// To resolve this, we will use this forward to automatically put a client on a team
// when afk-manager4 detects that they have returned from being afk.
#if defined _afkmanager_included
public void AFKM_OnClientBack(int client)
{
	if (cvar_BlockTeamSwitch.IntValue != 2)
	{
		return;
	}
	int team = GetClientTeam(client);
	if (team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		return;
	}
	Call_StartForward(g_AFKReturnForward);
	Call_PushCell(client);
	Call_Finish();
	PutClientOnATeam(client);
}
#endif
