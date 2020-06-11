#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <gameme>
#include <kento_rankme/rankme>
#include <lvl_ranks>
#include <NCIncs/nc_rpg.inc>
#pragma newdecls required
#pragma semicolon 1

#define UNASSIGNED 0
#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3
#define TYPE_GAMEME 3
#define TYPE_RANKME 4
#define TYPE_LVLRanks 5
#define TYPE_NCRPG 6

public Plugin myinfo =
{
	name = "SkillAutoBalance",
	author = "Justin (ff)",
	description = "A configurable automated team manager",
	version = "3.1.1",
	url = "https://steamcommunity.com/id/NameNotJustin/"
}

enum struct PlayerInfo
{
	int target;
	int targetUserId;
}

bool
	g_AllowSpawn = true,
	g_ForceBalance,
	g_Balancing,
	g_iClientFrozen[MAXPLAYERS + 1],
	g_iClientOutlier[MAXPLAYERS + 1],
	g_iClientForceJoin[MAXPLAYERS + 1],
	g_UsingAdminmenu,
	g_UsingGameME,
	g_UsingRankME,
	g_UsingLVLRanks,
	g_UsingNCRPG,
	g_SetTeamHooked = false,
	g_ForceBalanceHooked = false,
	g_LateLoad = false,
	g_MapLoaded = false
;

char
	g_MessageColor[4],
	g_PrefixColor[4],
	g_Prefix[20]
;

ConVar
	cvar_BalanceAfterNPlayersChange,
	cvar_BalanceAfterNRounds,
	cvar_BalanceEveryRound,
	cvar_RoundRestartDelay,
	cvar_RoundTime,
	cvar_GraceTime,
	cvar_ScoreType,
	cvar_TeamMenu,
	cvar_UseDecay,
	cvar_DecayAmount,
	cvar_MinPlayers,
	cvar_MinStreak,
	cvar_Scale,
	cvar_Scramble,
	cvar_ForceJoinTeam,
	cvar_ChatChangeTeam,
	cvar_SetTeam,
	cvar_ForceBalance,
	cvar_MessageType,
	cvar_MessageColor,
	cvar_Prefix,
	cvar_PrefixColor,
	cvar_DisplayChatMessages,
	cvar_BlockTeamSwitch,
	cvar_KeepPlayersAlive
;

float
	g_iClientScore[MAXPLAYERS + 1],
	g_iStreak[2],
	g_LastAverageScore
;

int
	g_PlayerCount = 0,
	g_PlayerCountChange = 0,
	g_RoundCount = 0,
	g_iClient[MAXPLAYERS - 1] = {1, 2, ...},
	g_iClientTeam[MAXPLAYERS + 1],
	g_iClientForceJoinPreference[MAXPLAYERS + 1]
;

Handle g_hForceSpawn;

TopMenu hTopMenu = null;

PlayerInfo playerinfo[MAXPLAYERS + 1];

StringMap colors;

/* Plugin-Related Functions */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_LateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	InitColorStringMap();

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_connect_full", Event_PlayerConnectFull);

	AddCommandListener(CommandList_JoinTeam, "jointeam");

	cvar_BalanceAfterNRounds = CreateConVar("sab_balanceafternrounds", "0", "0 = Disabled. Otherwise, after map change balance teams when 'N' rounds pass. Then balance based on team win streaks", _, true, 0.0);
	cvar_BalanceAfterNPlayersChange = CreateConVar("sab_balanceafternplayerschange", "0", "0 = Disabled. Otherwise, balance  teams when 'N' players join/leave the server. Requires sab_balanceafternrounds to be enabled", _, true, 0.0);
	cvar_BalanceEveryRound = CreateConVar("sab_balanceeveryround", "0", "If enabled, teams will be rebalanced at the end of every round", _, true, 0.0, true, 1.0);
	cvar_BlockTeamSwitch = CreateConVar("sab_blockteamswitch", "0", "0 = Don't block. 1 = Block, can join spectate, must rejoin same team. 2 = Block completely (also disables teammenu and chatchangeteam commands like !join !spec)", _, true, 0.0, true, 2.0);
	cvar_ChatChangeTeam = CreateConVar("sab_chatchangeteam", "0", "Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)", _, true, 0.0, true, 1.0);
	cvar_DecayAmount = CreateConVar("sab_decayamount", "1.5", "The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur.", _, true, 1.0);
	cvar_DisplayChatMessages = CreateConVar("sab_displaychatmessages", "1", "Allow plugin to display messages in the chat", _, true, 0.0, true, 1.0);
	cvar_ForceBalance = CreateConVar("sab_forcebalance", "0", "Add 'force balance' to 'server commands' in generic admin menu", _, true, 0.0, true, 1.0);
	cvar_ForceJoinTeam = CreateConVar("sab_forcejointeam", "0", "0 = Disabled, 1 = Optional (!settings), 2 = Forced. Force clients to join a team upon connecting to the server. Always enabled if both sab_chatchangeteam and sab_teammenu are disabled", _, true, 0.0, true, 2.0);
	cvar_GraceTime = FindConVar("mp_join_grace_time");
	cvar_KeepPlayersAlive = CreateConVar("sab_keepplayersalive", "1", "Living players are kept alive when their teams are changed", _, true, 0.0, true, 1.0);
	cvar_MessageColor = CreateConVar("sab_messagecolor", "white", "See sab_messagetype for info");
	cvar_MessageType = CreateConVar("sab_messagetype", "0", "How this plugin's messages will be colored in chat. 0 = no color, 1 = color only prefix with sab_prefixcolor, 2 = color entire message with sab_messagecolor, 3 = color prefix and message with both sab_prefixcolor and sab_messagecolor", _, true, 0.0, true, 3.0);
	cvar_MinPlayers = CreateConVar("sab_minplayers", "7", "The amount of players not in spectate must be at least this number for a balance to occur", _, true, 2.0);
	cvar_MinStreak = CreateConVar("sab_minstreak", "6", "Amount of wins in a row a team needs before autobalance occurs", _, true, 0.0);
	cvar_Prefix = CreateConVar("sab_prefix", "[SAB]", "The prefix for messages this plugin writes in the server");
	cvar_PrefixColor = CreateConVar("sab_prefixcolor", "white", "See sab_messagetype for info");
	cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	cvar_RoundTime = FindConVar("mp_roundtime");
	cvar_Scale = CreateConVar("sab_scale", "1.5", "Value to multiply IQR by. If your points have low spread keep this number. If your points have high spread change this to a lower number, like 0.5", _, true, 0.1);
	cvar_ScoreType = CreateConVar("sab_scoretype", "0", "Formula used to determine player 'skill'. 0 = K/D, 1 = K/D + K/10 - D/20, 2 = K^2/D, 3 = gameME rank, 4 = RankME, 5 = LVL Ranks, 6 = NCRPG", _, true, 0.0, true, 6.0);
	cvar_Scramble = CreateConVar("sab_scramble", "0", "Randomize teams instead of using a skill formula", _, true, 0.0, true, 1.0);
	cvar_SetTeam = CreateConVar("sab_setteam", "0", "Add 'set player team' to 'player commands' in generic admin menu", _, true, 0.0, true, 1.0);
	cvar_TeamMenu = CreateConVar("sab_teammenu", "1", "Whether to enable or disable the join team menu.", _, true, 0.0, true, 1.0);
	cvar_UseDecay = CreateConVar("sab_usedecay", "1", "If 1, subtract sab_decayamount from a team's streak when they lose instead of setting their streak to 0", _, true, 0.0, true, 1.0);

	cvar_ForceBalance.AddChangeHook(UpdateForceBalance);
	cvar_MessageColor.AddChangeHook(UpdateMessageColor);
	cvar_MessageType.AddChangeHook(UpdateMessageType);
	cvar_Prefix.AddChangeHook(UpdatePrefix);
	cvar_PrefixColor.AddChangeHook(UpdatePrefixColor);
	cvar_SetTeam.AddChangeHook(UpdateSetTeam);
	cvar_TeamMenu.AddChangeHook(UpdateTeamMenu);
	cvar_BlockTeamSwitch.AddChangeHook(UpdateBlockTeamSwitch);

	RegConsoleCmd("sm_j", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_join", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_p", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_play", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_s", Command_Spectate, "Switches player to spectator team");
	RegConsoleCmd("sm_spec", Command_Spectate, "Switches player to spectator team");
	RegConsoleCmd("sm_spectate", Command_Spectate, "Switches player to spectator team");

	AutoExecConfig(true, "SkillAutoBalance");

	LoadTranslations("skillautobalance.phrases");
	LoadTranslations("common.phrases");

	char cookieMenuTitle[100];
	Format(cookieMenuTitle, sizeof(cookieMenuTitle), "%t", "Auto-Join Preference");

	g_hForceSpawn = RegClientCookie("sab_forcespawn", "Auto-Join On Connect", CookieAccess_Private);

	SetCookieMenuItem(Cookie_ForceSpawnPreference, 1, cookieMenuTitle);

	if (g_LateLoad)
	{
		OnConfigsExecuted();
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(g_iClient[i]))
			{
				g_iClientTeam[i] = GetClientTeam(g_iClient[i]);
			}
		}	
	}
}

public void OnConfigsExecuted()
{
	char str[1];
	UpdateTeamMenu(cvar_TeamMenu, str, str);
	UpdateSetTeam(cvar_SetTeam, str, str);
	UpdateForceBalance(cvar_ForceBalance, str, str);
	UpdatePrefix(cvar_Prefix, str, str);
	UpdatePrefixColor(cvar_PrefixColor, str, str);
	UpdateMessageType(cvar_MessageType, str, str);
	UpdateBlockTeamSwitch(cvar_BlockTeamSwitch, str, str);
}
void UpdateTeamMenu(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_MapLoaded)
	{
		if (convar.BoolValue && cvar_BlockTeamSwitch.IntValue != 2)
		{
			GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
			return;
		}
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
	}
}
void UpdateBlockTeamSwitch(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_MapLoaded)
	{
		if (convar.IntValue == 2)
		{
			GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
		}
	}
}
void UpdateSetTeam(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_UsingAdminmenu && !g_SetTeamHooked && convar.BoolValue)
	{
		RegAdminCmd("sm_setteam", Command_SetTeam, ADMFLAG_SLAY, "Set player to CT, T, or SPEC");
		TopMenu topmenu;
		if ((topmenu = GetAdminTopMenu()) != null)
		{
			OnAdminMenuReady(topmenu);
			AttachSetTeamAdminMenu();
			g_SetTeamHooked = true;
		}
	}
}
void UpdateForceBalance(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_UsingAdminmenu && !g_ForceBalanceHooked && convar.BoolValue)
	{
		RegAdminCmd("sm_balance", Command_Balance, ADMFLAG_SLAY, "Forces a team balance to occur at the end of this round");
		TopMenu topmenu;
		if ((topmenu = GetAdminTopMenu()) != null)
		{
			OnAdminMenuReady(topmenu);
			AttachForceBalanceAdminMenu();
			g_ForceBalanceHooked = true;
		}
	}
}
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "gameme"))
	{
		g_UsingGameME = true;
	}
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = true;
	}
	if (StrEqual(name, "kento_rankme"))
	{
		g_UsingRankME = true;
	}
	if (StrEqual(name, "lvl_ranks"))
	{
		g_UsingLVLRanks = true;
	}
	if (StrEqual(name, "NCRPG"))
	{
		g_UsingNCRPG = true;
	}
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "gameme"))
	{
		g_UsingGameME = false;
	}
	if (StrEqual(name, "adminmenu"))
	{
		g_UsingAdminmenu = false;
	}
	if (StrEqual(name, "kento_rankme"))
	{
		g_UsingRankME = false;
	}
	if (StrEqual(name, "lvl_ranks"))
	{
		g_UsingLVLRanks = false;
	}
	if (StrEqual(name, "NCRPG"))
	{
		g_UsingNCRPG = false;
	}
}
void InitColorStringMap()
{
	colors = new StringMap();
	colors.SetString("red", "\x07");
	colors.SetString("white", "\x01");
	colors.SetString("lightred", "\x0F");
	colors.SetString("darkred", "\x02");
	colors.SetString("bluegrey", "\x0A");
	colors.SetString("blue", "\x0B");
	colors.SetString("darkblue", "\x0C");
	colors.SetString("orchid", "\x0E");
	colors.SetString("yellow", "\x09");
	colors.SetString("gold", "\x10");
	colors.SetString("lightgreen", "\x05");
	colors.SetString("green", "\x04");
	colors.SetString("lime", "\x06");
	colors.SetString("grey", "\x08");
	colors.SetString("grey2", "\x0D");
}

/* Public Map-Related Functions */
public void OnMapStart()
{
	g_AllowSpawn = true;
	g_MapLoaded = true;
	g_PlayerCount = 0;
	g_PlayerCountChange = 0;
	g_RoundCount = 0;
	if (cvar_TeamMenu.BoolValue)
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
	}
	else
	{
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
	}
	g_iStreak[0] = 0.0;
	g_iStreak[1] = 0.0;
}
public void OnMapEnd()
{
	g_MapLoaded = false;
}

/* Events */
void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_PlayerCount = 0;
	g_Balancing = false;
	bool warmupActive = IsWarmupActive();
	if (warmupActive)
	{
		g_AllowSpawn = true;
		return;
	}
	if (cvar_GraceTime.BoolValue)
	{
		g_AllowSpawn = true;
		CreateTimer(cvar_GraceTime.FloatValue, Timer_GraceTimeOver, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}
void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	g_AllowSpawn = false;
	++g_RoundCount;
	BalanceTeamCount();
	if(GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT) >= cvar_MinPlayers.IntValue)
	{
		SetStreak((GetEventInt(event, "winner") == TEAM_T) ? TEAM_T : TEAM_CT);
		if(g_ForceBalance || BalanceSkillNeeded())
		{
			g_Balancing = true;
			if (cvar_Scramble.BoolValue)
			{
				if (cvar_DisplayChatMessages.BoolValue)
				{
					ColorPrintToChatAll("Global Scramble Teams");
				}
				ScrambleTeams();
			}
			else
			{
				g_LastAverageScore = GetAverageScore();
				UpdateScores();
				g_iStreak[0] = 0.0;
				g_iStreak[1] = 0.0;
				g_PlayerCountChange = 0;
			}
		}
	}
	g_ForceBalance = false;
}
void Event_PlayerConnectFull(Event event, const char[] name, bool dontBroadcast)
{
	int userId = event.GetInt("userid");
	int client = GetClientOfUserId(userId);
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	g_iClientTeam[client] = TEAM_SPEC;
	g_iClientScore[client] = -1.0;
	g_iClientFrozen[client] = false;
	g_iClientOutlier[client] = false;
	++g_PlayerCountChange;
	if (!cvar_TeamMenu.BoolValue && cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Team Menu Disabled");
	}
	if ((cvar_ForceJoinTeam.IntValue == 1 && g_iClientForceJoinPreference[client] == 1) || cvar_ForceJoinTeam.IntValue == 2 || (!cvar_ChatChangeTeam.BoolValue && !cvar_TeamMenu.BoolValue && cvar_BlockTeamSwitch.IntValue > 0))
	{
		g_iClientForceJoin[client] = true;
		int team = GetSmallestTeam();
		ClientCommand(client, "jointeam 0 %i", team);
		if (!IsPlayerAlive(client) && (g_iClientTeam[client] == TEAM_T || g_iClientTeam[client] == TEAM_CT) && (g_AllowSpawn || AreTeamsEmpty()))
		{
			CS_RespawnPlayer(client);
		}
	}
	else
	{
		g_iClientForceJoin[client] = false;
	}
	GetScore(client);
}

/* Console Commands */
Action Command_Join(int client, int args)
{
	int team;
	if (cvar_ChatChangeTeam.BoolValue && (cvar_BlockTeamSwitch.IntValue != 2) && client != 0 && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_T && team != TEAM_CT)
	{
		if (g_iClientTeam[client] == TEAM_SPEC || g_iClientTeam[client] == UNASSIGNED)
		{
			SwapPlayer(client, GetSmallestTeam(), "Auto Join");
		}
		else if (CanJoin(client, g_iClientTeam[client], false))
		{
			SwapPlayer(client, g_iClientTeam[client], "Auto Join");
		}
		else if (g_iClientTeam[client] == TEAM_T)
		{
			SwapPlayer(client, TEAM_CT, "Auto Join");
		}
		else
		{
			SwapPlayer(client, TEAM_T, "Auto Join");
		}
	}
	return Plugin_Handled;
}
Action Command_Spectate(int client, int args)
{
	int team;
	if (cvar_ChatChangeTeam.BoolValue && (cvar_BlockTeamSwitch.IntValue != 2) && client != 0 && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
	{
		if (IsPlayerAlive(client))
		{
			ForcePlayerSuicide(client);
		}
		ChangeClientTeam(client, TEAM_SPEC);
	}
	return Plugin_Handled;
}
Action Command_Balance(int client, int args)
{
	g_ForceBalance = true;
	if (client == 0)
	{
		PrefixPrintToServer("Admin Force Balance");
	}
	else if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Admin Force Balance");
	}
	return Plugin_Handled;
}
Action Command_SetTeam(int client, int args)
{
	if (args < 2)
	{
		if (client == 0)
		{
			PrefixPrintToServer("Incorrect SetTeam Usage");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Incorrect SetTeam Usage");
		}
		return Plugin_Handled;
	}
	char buff[32];
	GetCmdArg(1, buff, sizeof(buff));
	int client1 = FindTarget(client, buff);
	if (client1 == -1)
	{
		if (client == 0)
		{
			PrefixPrintToServer("Client Not Found");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Client Not Found");
		}
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(2, buff, sizeof(buff));
		if (strcmp(buff, "ct", false) == 0 || strcmp(buff, "3", false) == 0)
		{
			SwapPlayer(client1, TEAM_CT, "Admin Join");
		}
		else if(strcmp(buff, "t", false) == 0 || strcmp(buff, "2", false) == 0)
		{
			SwapPlayer(client1, TEAM_T, "Admin Join");
		}
		else if (strcmp(buff, "spec", false) == 0 || strcmp(buff, "1", false) == 0)
		{
			SwapPlayer(client1, TEAM_SPEC, "Admin Join");
		}
		if (client == 0)
		{
			PrefixPrintToServer("Admin Client Swapped");
		}
		else if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Admin Client Swapped");
		}
		return Plugin_Handled;
	}
}

/* Timer Callbacks*/
void DelayTeamUpdate(int userId)
{
	int client = GetClientOfUserId(userId);
	if (client != 0 && IsClientInGame(client) && g_iClientTeam[client] == TEAM_SPEC)
	{
		g_iClientTeam[client] = GetClientTeam(client);
	}
}
Action Timer_GraceTimeOver(Handle timer)
{
	g_AllowSpawn = false;
	return Plugin_Handled;
}
Action Timer_UnpacifyPlayer(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);
	g_iClientFrozen[client] = false;
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	return Plugin_Handled;
}
Action Timer_CheckScore(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (client != 0 && IsClientInGame(client))
	{
		if (g_iClientScore[client] == -1)
		{
			g_iClientScore[client] = g_LastAverageScore;
		}
		if (g_Balancing)
		{
			++g_PlayerCount;
			if (g_PlayerCount == GetClientCountNoBots())
			{
				BalanceSkill();
			}
		}
	}
	return Plugin_Handled;
}
/* Internal Map-Related Functions */
bool IsWarmupActive()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}
bool AreTeamsEmpty()
{
	return !(GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT));
}

/* Internal Client-Related Functions */
int GetClientCountNoBots()
{
	int amount = 0;
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			++amount;
		}
	}
	return amount;
}
bool CanJoin(int client, int team, bool printMessage)
{
	int count[2];
	count[0] = GetTeamClientCount(TEAM_T);
	count[1] = GetTeamClientCount(TEAM_CT);
	int newTeamCount = count[team - 2];
	int otherTeamCount = count[(team + 1) % 2];
	int currentTeam = GetClientTeam(client);
	if (newTeamCount > otherTeamCount)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Team Has More Players");
		}
		return false;
	}
	else if (newTeamCount == otherTeamCount && g_iClientTeam[client] == team)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Must Join Previous Team");
		}
		return true;
	}
	else if (newTeamCount < otherTeamCount && currentTeam != TEAM_T && currentTeam != TEAM_CT)
	{
		if (cvar_DisplayChatMessages.BoolValue && printMessage)
		{
			ColorPrintToChat(client, "Must Join Previous Team");
		}
		return true;
	}
	return false;
}
void SwapPlayer(int client, int team, char reason[50])
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, reason);
	}
	g_iClientTeam[client] = team;
	if(team != TEAM_SPEC && team != UNASSIGNED)
	{
		if (IsPlayerAlive(client) && cvar_KeepPlayersAlive.BoolValue)
		{
			CS_SwitchTeam(client, team);
			CS_UpdateClientModel(client);
			PacifyPlayer(client);
			return;
		}
		ChangeClientTeam(client, team);
		return;
	}
	if (IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
	ChangeClientTeam(client, TEAM_SPEC);
}
void PacifyPlayer(int client)
{
	if(cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChat(client, "Pacified Client");
	}
	CS_UpdateClientModel(client);
	g_iClientFrozen[client] = true;
	SetEntityRenderColor(client, 0, 170, 174, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer(cvar_RoundRestartDelay.FloatValue, Timer_UnpacifyPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}
void UpdateScores()
{
	int client;
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (client != 0 && IsClientInGame(client))
		{
			GetScore(client);
		}
	}
}
void GetScore(int client)
{
	g_iClientScore[client] = -1.0;
	int scoreType = cvar_ScoreType.IntValue;
	if (scoreType == TYPE_GAMEME)
	{
		if (g_UsingGameME)
		{
			QueryGameMEStats("playerinfo", client, GameMEStatsCallback, 1);
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("GameME not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_RANKME)
	{
		if (g_UsingRankME)
		{
			g_iClientScore[client] = float(RankMe_GetPoints(client));
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("kento_rankme not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_LVLRanks)
	{
		if (g_UsingLVLRanks)
		{
			g_iClientScore[client] = float(LR_GetClientInfo(client, ST_EXP));
			CreateTimer(0.1, Timer_CheckScore, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			LogError("LVL Ranks not found. Use other score type");
		}
	}
	else if (scoreType == TYPE_NCRPG)
	{
		if (g_UsingNCRPG)
		{
			g_iClientScore[client] = float(NCRPG_GetLevel(client));
		}
		else
		{
			LogError("NCRPG not found. Use other score type");
		}
	}
	else
	{
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
			if (g_PlayerCount == GetClientCountNoBots())
			{
				BalanceSkill();
				g_PlayerCount = 0;
			}
		}
	}
}

/* Internal Team-Related Functions */
void SetStreak(int winningTeam)
{
	if (winningTeam >= 2)
	{
		float decayAmount = cvar_DecayAmount.FloatValue;
		int winnerIndex = winningTeam - 2;
		int loserIndex 	= (winningTeam + 1) % 2;
		++g_iStreak[winnerIndex];
		if (cvar_UseDecay.BoolValue)
		{
			g_iStreak[loserIndex] = (g_iStreak[loserIndex] > decayAmount) ? (g_iStreak[loserIndex] - decayAmount) : 0.0;
		}
		else
		{
			g_iStreak[loserIndex] = 0.0;
		}
	}
}
int GetSmallestTeam()
{
	int tSize = GetTeamClientCount(TEAM_T);
	int ctSize = GetTeamClientCount(TEAM_CT);
	return tSize == ctSize ? GetRandomInt(TEAM_T, TEAM_CT) : tSize < ctSize ? TEAM_T : TEAM_CT;
}
void BalanceTeamCount()
{
	int teams[2] = {2, 3};
	int smallIndex = GetSmallestTeam() - 2;
	int bigIndex = (smallIndex + 1) % 2;
	int client;
	int i = 0;
	SortIntegers(g_iClient, sizeof(g_iClient), Sort_Random);
	while(i < sizeof(g_iClient) && (GetTeamClientCount(teams[bigIndex]) - GetTeamClientCount(teams[smallIndex]) > 1))
	{
		client = g_iClient[i];
		if (client != 0 && IsClientInGame(client) && GetClientTeam(client) == teams[bigIndex])
		{
			SwapPlayer(client, teams[smallIndex], "Team Count Balance");
		}
		++i;
	}
}
bool BalanceSkillNeeded()
{
	int time;
	GetMapTimeLeft(time);
	int minStreak = cvar_MinStreak.IntValue;
	if (time > (cvar_RoundTime.FloatValue * 60 + cvar_RoundRestartDelay.FloatValue + 1))
	{
		if (cvar_BalanceEveryRound.BoolValue)
		{
			return true;
		}
		else if (g_iStreak[0] >= minStreak || g_iStreak[1] >= minStreak)
		{
			return true;
		}
		else if(cvar_BalanceAfterNRounds.BoolValue)
		{
			if (g_RoundCount == cvar_BalanceAfterNRounds.IntValue)
			{
				return true;
			}
			else if (cvar_BalanceAfterNPlayersChange.BoolValue && g_RoundCount >= cvar_BalanceAfterNRounds.IntValue)
			{
				if (g_PlayerCountChange >= cvar_BalanceAfterNPlayersChange.IntValue)
				{
					return true;
				}
			}
		}
	}
	return false;
}
int Sort_Scores(int client1, int client2, const int[] array, Handle hndl)
{
	float client1Score = g_iClientScore[client1];
	float client2Score = g_iClientScore[client2];
	if(client1Score == client2Score)
	{
		return 0;
	}
	return client1Score > client2Score ? -1 : 1;
}
float GetAverageScore()
{
	int count = GetClientCountNoBots();
	float sum = 0.0;
	int client;
	for (int i = 0; i < count; ++i)
	{
		client = g_iClient[i];
		sum += g_iClientScore[client];
	}
	return sum / count;
}
void ScrambleTeams()
{
	SortIntegers(g_iClient, sizeof(g_iClient), Sort_Random);
	int teams[2] = {2, 3};
	int nextTeam = GetSmallestTeam() - 2;
	int client, team;
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (client == 0 || !IsClientInGame(client) || IsFakeClient(client) || (team = GetClientTeam(client)) == TEAM_SPEC || team == UNASSIGNED)
		{
			continue;
		}
		if (g_iClientTeam[client] != teams[nextTeam])
		{
			SwapPlayer(client, teams[nextTeam], "Client Scramble Team");
		}
		nextTeam = (nextTeam + 1) % 2;
	}
}
int RemoveOutliers()
{
	int outliers = 0;
	int size = GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT);
	int q1Start = 0;
	int q3End = size - 1;
	float q1Med, q3Med, IQR;
	int q1End, q1Size, q3Start, q3Size;
	if (size % 2 == 0)
	{
		q1End = size / 2 - 1;
		q1Size = q1End - q1Start + 1;
		q3Start = size / 2;
		q3Size = q3End - q3Start + 1;
		if (q1Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q1Size / 2 - 1 + q1Start];
			int rightClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = (g_iClientScore[leftClientIndex] + g_iClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = g_iClientScore[medianClientIndex];
		}
		if (q3Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q3Size / 2 - 1 + q3Start];
			int rightClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = (g_iClientScore[leftClientIndex] + g_iClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = g_iClientScore[medianClientIndex];
		}
	}
	else
	{
		q1End = size / 2 - 1;
		q1Size = q1End - q1Start + 1;
		q3Start = size / 2 + 1;
		q3Size = q3End - q3Start + 1;
		if (q1Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q1Size / 2 - 1 + q1Start];
			int rightClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = (g_iClientScore[leftClientIndex] + g_iClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q1Size / 2 + q1Start];
			q1Med = g_iClientScore[medianClientIndex];
		}
		if (q3Size % 2 == 0)
		{
			int leftClientIndex = g_iClient[q3Size / 2 - 1 + q3Start];
			int rightClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = (g_iClientScore[leftClientIndex] + g_iClientScore[rightClientIndex]) / 2;
		}
		else
		{
			int medianClientIndex = g_iClient[q3Size / 2 + q3Start];
			q3Med = g_iClientScore[medianClientIndex];
		}
	}
	IQR = q1Med - q3Med;
	float lowerBound = q3Med - cvar_Scale.IntValue * IQR;
	float upperBound = q1Med + cvar_Scale.IntValue * IQR;
	int client, team;
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (g_iClientScore[client] > upperBound || g_iClientScore[client] < lowerBound) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
		{
			g_iClientOutlier[client] = true;
			outliers++;
		}
	}
	return outliers;
}
void AddOutliers(int sizes[2])
{
	int client, team;
	int teams[2] = {2, 3};
	int nextTeam = (sizes[0] <= sizes[1] ? 0 : 1);
	for (int i = 0; i < sizeof(g_iClient); ++i)
	{
		client = g_iClient[i];
		if (g_iClientOutlier[client] && client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
		{
			if (g_iClientTeam[client] != teams[nextTeam])
			{
				SwapPlayer(client, teams[nextTeam], "Client Skill Balance");
			}
			nextTeam = (nextTeam + 1) % 2;
		}
		g_iClientOutlier[client] = false;
	}
}
int SortCloseSums(int outliers)
{
	int sizes[2];
	int client, team;
	int i = 0;
	int totalSize = GetTeamClientCount(TEAM_T) + GetTeamClientCount(TEAM_CT) - outliers;
	int smallTeamSize = totalSize / 2;
	int bigTeamSize = smallTeamSize;
	if (totalSize % 2 == 1)
	{
		++bigTeamSize;
	}
	float tSum = 0.0;
	float ctSum = 0.0;
	int tCount = 0;
	int ctCount = 0;
	while(tCount < bigTeamSize && ctCount < bigTeamSize)
	{
		client = g_iClient[i];
		if (client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED && !g_iClientOutlier[client])
		{
			if (tSum < ctSum)
			{
				tSum += g_iClientScore[client];
				++tCount;
				if (g_iClientTeam[client] == TEAM_CT)
				{
					SwapPlayer(client, TEAM_T, "Client Skill Balance");
				}
			}
			else
			{
				ctSum += g_iClientScore[client];
				++ctCount;
				if (g_iClientTeam[client] == TEAM_T)
				{
					SwapPlayer(client, TEAM_CT, "Client Skill Balance");
				}
			}
		}
		++i;
	}
	while(i < sizeof(g_iClient))
	{
		client = g_iClient[i];
		if (client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED && !g_iClientOutlier[client])
		{
			if (tCount < smallTeamSize)
			{
				++tCount;
				if (g_iClientTeam[client] == TEAM_CT)
				{
					SwapPlayer(client, TEAM_T, "Client Skill Balance");
				}
			}
			else if (ctCount < smallTeamSize)
			{
				++ctCount;
				if(g_iClientTeam[client] == TEAM_T)
				{
					SwapPlayer(client, TEAM_CT, "Client Skill Balance");
				}
			}
		}
		++i;
	}
	sizes[0] = tCount;
	sizes[1] = ctCount;
	return sizes;
}
void BalanceSkill()
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChatAll("Global Skill Balance");
	}
	SortCustom1D(g_iClient, sizeof(g_iClient), Sort_Scores);
	int outliers = RemoveOutliers();
	int sizes[2];
	sizes = SortCloseSums(outliers);
	if (outliers > 0)
	{
		AddOutliers(sizes);
	}
}

/* Public Client-Related Functions */
public void OnClientCookiesCached(int client)
{
	char buffer[24];
	GetClientCookie(client, g_hForceSpawn, buffer, sizeof(buffer));
	if (strlen(buffer) > 0)
	{
		g_iClientForceJoinPreference[client] = StringToInt(buffer);
	}
}
public void OnClientDisconnect(int client)
{
	g_iClientTeam[client] = TEAM_SPEC;
	g_iClientScore[client] = -1.0;
	g_iClientFrozen[client] = false;
	g_iClientOutlier[client] = false;
	++g_PlayerCountChange;
	if (!AreTeamsEmpty())
	{
		return;
	}
	g_AllowSpawn = true;
}
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (g_iClientFrozen[client])
	{
		buttons &= ~IN_ATTACK2;
		buttons &= ~IN_ATTACK;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

/* Other Plugin Callbacks */
Action GameMEStatsCallback(int command, int payload, int client, Handle datapack)
{
	int argument_count = GetCmdArgs();
	g_iClientScore[client] = float(get_param(6, argument_count));
}
int get_param(int index, int argument_count) 
{
	char param[128];
	if (index <= argument_count)
	{
		GetCmdArg(index, param, 128);
		return StringToInt(param);
	}
	return -1;
}

/* Command Listeners */
Action CommandList_JoinTeam(int client, const char[] command, int argc)
{
	if (cvar_BlockTeamSwitch.IntValue == 0)
	{
		return Plugin_Continue;
	}
	if (g_iClientForceJoin[client])
	{
		g_iClientForceJoin[client] = false;
		RequestFrame(DelayTeamUpdate, GetClientUserId(client));
		return Plugin_Continue;
	}
	if (cvar_BlockTeamSwitch.IntValue == 2)
	{
		return Plugin_Stop;
	}
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	int team = StringToInt(arg);
	if (team == UNASSIGNED)
	{
		return Plugin_Stop;
	}
	if (team == TEAM_SPEC)
	{
		return Plugin_Continue;
	}
	if (!CanJoin(client, team, true))
	{
		return Plugin_Stop;
	}
	RequestFrame(DelayTeamUpdate, GetClientUserId(client));
	return Plugin_Continue;
}

/* Menu Functions */
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
	if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
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
int MenuHandler_ForceJoin(Menu menu, MenuAction action, int client, int option)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		char menuItem[32];
		menu.GetItem(option, menuItem, sizeof(menuItem));
		if (StringToInt(menuItem) == 0)
		{
			g_iClientForceJoinPreference[client] = 0;
		}
		else if (StringToInt(menuItem) == 1)
		{
			g_iClientForceJoinPreference[client] = 1;
		}
	}
	// Adding a bunch of checks because I have no fucking clue why I'm getting client index 0 is invalid here. Earlier, I return when client index is 0, so why is it changing to 0?
	if (client != 0 && IsClientInGame(client) && IsFakeClient(client))
	{
		char sCookieValue[12];
		IntToString(g_iClientForceJoinPreference[client], sCookieValue, sizeof(sCookieValue));
		SetClientCookie(client, g_hForceSpawn, sCookieValue);
		return;
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
		if (client == 0)
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

/* Color-Related Functions */
void UpdateMessageType(ConVar convar, char [] oldValue, char [] newValue)
{
	char str[20];
	GetConVarString(cvar_MessageColor, str, sizeof(str));
	UpdateMessageColor(cvar_MessageColor, str, str);
	str[0] = '\0';
	GetConVarString(cvar_PrefixColor, str, sizeof(str));
	UpdatePrefixColor(cvar_PrefixColor, str, str);
}
void UpdateMessageColor(ConVar convar, char [] oldValue, char [] newValue)
{
	char sMessageColor[20];
	GetConVarString(convar, sMessageColor, sizeof(sMessageColor));
	int messageType = cvar_MessageType.IntValue;
	if (messageType == 0 || messageType == 1)
	{
		g_MessageColor = "\x01";
	}
	else if(messageType == 2 || messageType == 3)
	{
		SetColor(g_MessageColor, sMessageColor);
	}
}
void UpdatePrefixColor(ConVar convar, char [] oldValue, char [] newValue)
{
	char sPrefixColor[20];
	GetConVarString(convar, sPrefixColor, sizeof(sPrefixColor));
	int messageType = cvar_MessageType.IntValue;
	if (messageType == 0 || messageType == 2)
	{
		g_PrefixColor = "\x01";
	}
	else if(messageType == 1 || messageType == 3)
	{
		SetColor(g_PrefixColor, sPrefixColor);
	}
}
void UpdatePrefix(ConVar convar, char [] oldValue, char [] newValue)
{
	GetConVarString(convar, g_Prefix, sizeof(g_Prefix));
}
void SetColor(char str[4], char color[20])
{
	if (!colors.GetString(color, str, sizeof(str)))
	{
		str = "\x01";
	}
}
void AppendDataToString(char str[255])
{
	StrCat(str, sizeof(str), g_PrefixColor);
	StrCat(str, sizeof(str), g_Prefix);
	StrCat(str, sizeof(str), " ");
	StrCat(str, sizeof(str), g_MessageColor);
	StrCat(str, sizeof(str), "%t");
}
void ColorPrintToChat(int client, char phrase[50])
{
	char str[255] = " ";
	AppendDataToString(str);
	PrintToChat(client, str, phrase);
}
void ColorPrintToChatAll(char phrase[50])
{
	char str[255] = " ";
	AppendDataToString(str);
	PrintToChatAll(str, phrase);
}
void PrefixPrintToServer(char phrase[50])
{
	char str[255] = " ";
	AppendDataToString(str);
	PrintToServer(str, phrase);
}