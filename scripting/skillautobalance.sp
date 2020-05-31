#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_gamerules>
#include <cstrike>
#include <usermessages>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <gameme>
#include <kento_rankme/rankme>
#include <lvl_ranks>
#pragma newdecls required
#pragma semicolon 1

#define UNASSIGNED 0
#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3
#define TYPE_GAMEME 3
#define TYPE_RANKME 4
#define TYPE_LVLRanks 5

public Plugin myinfo =
{
	name = "SABREMAKE",
	author = "Justin (ff)",
	description = "Balance teams when one side is stacked",
	version = "3.0.2",
	url = "https://steamcommunity.com/id/NameNotJustin/"
}

enum struct PlayerInfo
{
	int target;
	int targetUserId;
}

ConVar
	cvar_RoundRestartDelay,
	cvar_RoundTime,
	cvar_ScoreType,
	cvar_TeamMenu,
	cvar_UseDecay,
	cvar_DecayAmount,
	cvar_MinPlayers,
	cvar_MinStreak,
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

int
	g_Count = 0,
	g_iClients[MAXPLAYERS + 1],
	g_iClientTeam[MAXPLAYERS + 1]
;

char
	g_MessageColor[4],
	g_PrefixColor[4],
	g_Prefix[20]
;

bool
	g_ForceBalance,
	g_Balancing,
	g_iFrozenClients[MAXPLAYERS + 1],
	g_iOutlierClients[MAXPLAYERS + 1],
	g_UsingGameME,
	g_UsingAdminmenu,
	g_UsingRankME,
	g_UsingLVLRanks,
	g_SetTeamHooked = false,
	g_ForceBalanceHooked = false,
	g_LateLoad = false,
	g_MapLoaded = false
;

float
	g_iClientScore[MAXPLAYERS + 1],
	g_iStreak[2],
	g_LastAverageScore
;

DataPack
	g_hPlayerCount
;

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
	InitPlayerCountDataPack(0);

	InitColorStringMap();

	HookEvent("round_end", Event_RoundEnd);

	AddCommandListener(CommandList_JoinTeam, "jointeam");

	cvar_BlockTeamSwitch = CreateConVar("sab_blockteamswitch", "0", "Prevent clients from switching team. Can join spectate. Can switch if it is impossible for them to rejoin same team due to team-size", _, true, 0.0, true, 1.0);
	cvar_ChatChangeTeam = CreateConVar("sab_chatchangeteam", "0", "Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)", _, true, 0.0, true, 1.0);
	cvar_DecayAmount = CreateConVar("sab_decayamount", "1.5", "The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur.", _, true, 1.0);
	cvar_DisplayChatMessages = CreateConVar("sab_displaychatmessages", "1", "Allow plugin to display messages in the chat", _, true, 0.0, true, 1.0);
	cvar_ForceBalance = CreateConVar("sab_forcebalance", "0", "Add 'force balance' to 'server commands' in generic admin menu", _, true, 0.0, true, 1.0);
	cvar_ForceJoinTeam = CreateConVar("sab_forcejointeam", "0", "Force clients to join a team upon connecting to the server. If both sab_chatchangeteam and sab_teammenu are disabled, this will always be enabled (otherwise, clients cannot join a team).", _, true, 0.0, true, 1.0);
	cvar_KeepPlayersAlive = CreateConVar("sab_keepplayersalive", "1", "Living players are kept alive when their teams are changed", _, true, 0.0, true, 1.0);
	cvar_MessageColor = CreateConVar("sab_messagecolor", "white", "See sab_messagetype for info");
	cvar_MessageType = CreateConVar("sab_messagetype", "0", "How this plugin's messages will be colored in chat. 0 = no color, 1 = color only prefix with sab_prefixcolor, 2 = color entire message with sab_messagecolor, 3 = color prefix and message with both sab_prefixcolor and sab_messagecolor", _, true, 0.0, true, 3.0);
	cvar_MinPlayers = CreateConVar("sab_minplayers", "7", "The amount of players not in spectate must be at least this number for a balance to occur", _, true, 2.0);
	cvar_MinStreak = CreateConVar("sab_minstreak", "6", "Amount of wins in a row a team needs before autobalance occurs", _, true, 0.0);
	cvar_Prefix = CreateConVar("sab_prefix", "[SAB]", "The prefix for messages this plugin writes in the server");
	cvar_PrefixColor = CreateConVar("sab_prefixcolor", "white", "See sab_messagetype for info");
	cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	cvar_RoundTime = FindConVar("mp_roundtime");
	cvar_ScoreType = CreateConVar("sab_scoretype", "0", "Formula used to determine player 'skill'. 0 = K/D, 1 = 2*K/D, 2 = K^2/D, 3 = gameME rank, 4 = RankME, 5 = LVL Ranks", _, true, 0.0, true, 5.0);
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

	RegConsoleCmd("sm_j", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_join", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_p", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_play", Command_Join, "Switches player to smallest team");
	RegConsoleCmd("sm_s", Command_Spectate, "Switches player to spectator team");
	RegConsoleCmd("sm_spec", Command_Spectate, "Switches player to spectator team");
	RegConsoleCmd("sm_spectate", Command_Spectate, "Switches player to spectator team");

	AutoExecConfig(true, "SkillAutoBalance");

	LoadTranslations("skillautobalance.phrases");

	if (g_LateLoad)
	{
		//g_hPlayerCount
		OnConfigsExecuted();
		for (int i = 1; i <= MaxClients; ++i)
		{
			g_iClients[i] = i;
			if (IsClientInGame(g_iClients[i]))
			{
				g_iClientTeam[i] = GetClientTeam(g_iClients[i]);
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
}
void UpdateTeamMenu(ConVar convar, char [] oldValue, char [] newValue)
{
	if (g_MapLoaded)
	{
		if (convar.BoolValue)
		{
			GameRules_SetProp("m_bIsQueuedMatchmaking", 0);
			return;
		}
		GameRules_SetProp("m_bIsQueuedMatchmaking", 1);
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
void InitPlayerCountDataPack(int updatedPlayers)
{
	if (g_hPlayerCount == INVALID_HANDLE)
	{
		g_hPlayerCount = new DataPack();
		WritePackCell(g_hPlayerCount, updatedPlayers);
	}
}

/* Public Map-Related Functions */
public void OnMapStart()
{
	g_MapLoaded = true;
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
	for (int i = 1; i <= MaxClients; ++i)
	{
		g_iClients[i] = i;
	}
}
public void OnMapEnd()
{
	g_MapLoaded = false;
}
public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	int tSize = GetTeamClientCount(TEAM_T);
	int ctSize = GetTeamClientCount(TEAM_CT);
	BalanceTeamCount();
	if(tSize + ctSize >= cvar_MinPlayers.IntValue)
	{
		int winningTeam = (GetEventInt(event, "winner") == TEAM_T) ? TEAM_T : TEAM_CT;
		SetStreak(winningTeam);
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
			}
		}
	}
	g_ForceBalance = false;
}

/* Console Commands */
Action Command_Join(int client, int args)
{
	int team;
	if (cvar_ChatChangeTeam.BoolValue && client != 0 && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_T && team != TEAM_CT)
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
	if (cvar_ChatChangeTeam.BoolValue && client != 0 && IsClientInGame(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
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
Action ForceSpectate(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (cvar_DisplayChatMessages.BoolValue)
		{
			ColorPrintToChat(client, "Team Menu Disabled");
		}
		SwapPlayer(client, TEAM_SPEC, "Delay Join");
		CreateTimer(2.0, PutOnRandomTeam, userId);
	}
	return Plugin_Handled;
}
Action UnpacifyPlayer(Handle timer, int userID)
{
	int client = GetClientOfUserId(userID);
	g_iFrozenClients[client] = false;
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
}
Action PutOnRandomTeam(Handle timer, int userId)
{
	int client = GetClientOfUserId(userId);
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SPEC)
	{
		SwapPlayer(client, GetSmallestTeam(), "Auto Join");
	}
}
Action CheckScore(Handle timer, int userId)
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
			++g_Count;
			if (g_Count == GetClientCountNoBots())
			{
				g_Balancing = false;
				BalanceSkill();
				g_Count = 0;
			}
		}
	}
	return Plugin_Handled;
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
	g_iFrozenClients[client] = true;
	SetEntityRenderColor(client, 0, 170, 174, 255);
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer(cvar_RoundRestartDelay.FloatValue, UnpacifyPlayer, GetClientUserId(client));
}
void UpdateScores()
{
	int client;
	for (int i = 0; i < sizeof(g_iClients); ++i)
	{
		client = g_iClients[i];
		if (client != 0 && IsClientInGame(client))
		{
			GetScore(client);
		}
	}
	if (cvar_ScoreType.IntValue != TYPE_GAMEME)
	{
		BalanceSkill();
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
			CreateTimer(0.5, CheckScore, GetClientUserId(client));
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
			CreateTimer(0.5, CheckScore, GetClientUserId(client));
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
			CreateTimer(0.5, CheckScore, GetClientUserId(client));
		}
		else
		{
			LogError("LVL Ranks not found. Use other score type");
		}
	}
	else
	{
		++g_Count;
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
			g_iClientScore[client] = 2 * kills / deaths;
		}
		else if(scoreType == 2)
		{
			g_iClientScore[client] = kills * kills / deaths;
		}
		if (g_Count == GetClientCountNoBots())
		{
			BalanceSkill();
			g_Count = 0;
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
	if(tSize == ctSize)
	{
		return GetRandomInt(TEAM_T, TEAM_CT);
	}
	return tSize < ctSize ? TEAM_T : TEAM_CT;
}
void BalanceTeamCount()
{
	int teams[2] = {2, 3};
	int smallIndex = GetSmallestTeam() - 2;
	int bigIndex = (smallIndex + 1) % 2;
	int client;
	int i = 0;
	SortIntegers(g_iClients, sizeof(g_iClients), Sort_Random);
	while(i < sizeof(g_iClients) && (GetTeamClientCount(teams[bigIndex]) - GetTeamClientCount(teams[smallIndex]) > 1))
	{
		client = g_iClients[i];
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
	if (time > (cvar_RoundTime.FloatValue * 60 + cvar_RoundRestartDelay.FloatValue + 1) && (g_iStreak[0] >= minStreak || g_iStreak[1] >= minStreak))
	{
		return true;
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
		client = g_iClients[i];
		sum += g_iClientScore[client];
	}
	return sum / count;
}
void ScrambleTeams()
{
	SortIntegers(g_iClients, sizeof(g_iClients), Sort_Random);
	int teams[2] = {2, 3};
	int nextTeam = GetSmallestTeam() - 2;
	int client, team;
	for (int i = 0; i < sizeof(g_iClients); ++i)
	{
		client = g_iClients[i];
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
	int size = GetClientCountNoBots();
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
			q1Med = (g_iClientScore[q1Size / 2 - 1 + q1Start] + g_iClientScore[q1Size / 2 + q1Start]) / 2;
		}
		else
		{
			q1Med = g_iClientScore[q1Size / 2 + q1Start];
		}
		if (q3Size % 2 == 0)
		{
			q3Med = (g_iClientScore[q3Size / 2 - 1 + q3Start] + g_iClientScore[q3Size / 2 + q3Start]) / 2;
		}
		else
		{
			q3Med = g_iClientScore[q3Size / 2 + q3Start];
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
			q1Med = (g_iClientScore[q1Size / 2 - 1 + q1Start] + g_iClientScore[q1Size / 2 + q1Start]) / 2;
		}
		else
		{
			q1Med = g_iClientScore[q1Size / 2 + q1Start];
		}
		if (q3Size % 2 == 0)
		{
			q3Med = (g_iClientScore[q3Size / 2 - 1 + q3Start] + g_iClientScore[q3Size / 2 + q3Start]) / 2;
		}
		else
		{
			q3Med = g_iClientScore[q3Size / 2 + q3Start];
		}
	}
	IQR = q3Med - q1Med;
	float upperBound = q3Med + 1.5 * IQR;
	float lowerBound = q1Med - 1.5 * IQR;
	int client;
	for (int i = 0; i < size; ++i)
	{
		client = g_iClients[i];
		if (g_iClientScore[client] > upperBound || g_iClientScore[client] < lowerBound)
		{
			g_iOutlierClients[client] = true;
			outliers++;
		}
	}
	return outliers;
}
void AddOutliers()
{
	int client, team;
	int teams[2] = {2, 3};
	int nextTeam = GetSmallestTeam() - 2;
	for (int i = 0; i < sizeof(g_iClients); ++i)
	{
		client = g_iClients[i];
		if (g_iOutlierClients[client] && client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
		{
			g_iOutlierClients[client] = false;
			if (g_iClientTeam[client] != teams[nextTeam])
			{
				SwapPlayer(client, teams[nextTeam], "Client Skill Balance");
			}
			nextTeam = (nextTeam + 1) % 2;
		}
	}
}
void SortCloseSums(int outliers)
{
	int client, team;
	int i = 0;
	int size = GetClientCountNoBots() / 2 - outliers;
	float tSum = 0.0;
	float ctSum = 0.0;
	int tCount = 0;
	int ctCount = 0;
	while(tCount < size && ctCount < size)
	{
		client = g_iClients[i];
		if (client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED && !g_iOutlierClients[client])
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
	while(i < sizeof(g_iClients))
	{
		client = g_iClients[i];
		if (client != 0 && IsClientInGame(client) && !IsFakeClient(client) && (team = GetClientTeam(client)) != TEAM_SPEC && team != UNASSIGNED)
		{
			if (tCount < size)
			{
				if (g_iClientTeam[client] == TEAM_CT)
				{
					SwapPlayer(client, TEAM_T, "Client Skill Balance");
				}
			}
			else
			{
				if(g_iClientTeam[client] == TEAM_T)
				{
					SwapPlayer(client, TEAM_CT, "Client Skill Balance");
				}
			}
		}
		++i;
	}
}
void BalanceSkill()
{
	if (cvar_DisplayChatMessages.BoolValue)
	{
		ColorPrintToChatAll("Global Skill Balance");
	}
	SortCustom1D(g_iClients, sizeof(g_iClients), Sort_Scores);
	int outliers = RemoveOutliers();
	SortCloseSums(outliers);
	AddOutliers();
}

/* Public Client-Related Functions */
public void OnClientPostAdminCheck(int client)
{
	g_iClientScore[client] = -1.0;
	g_iFrozenClients[client] = false;
	g_iOutlierClients[client] = false;
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (cvar_ForceJoinTeam.BoolValue || (!cvar_TeamMenu.BoolValue && !cvar_ChatChangeTeam.BoolValue))
		{
			CreateTimer(1.0, ForceSpectate, GetClientUserId(client));
		}
		GetScore(client);
	}
}
public Action OnPlayerRunCmd(int client, int &buttons)
{
	if (g_iFrozenClients[client])
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
	if (!cvar_TeamMenu.BoolValue)
	{
		ColorPrintToChat(client, "Team Menu Disabled");
		return Plugin_Stop;
	}
	if (!cvar_BlockTeamSwitch.BoolValue)
	{
		return Plugin_Continue;
	}
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	if(client != 0 && !IsClientInGame(client))
	{
		return Plugin_Stop;
	}
	char arg[5];
	GetCmdArg(1, arg, sizeof(arg));
	int newTeam = StringToInt(arg);
	if (newTeam == UNASSIGNED)
	{
		return Plugin_Stop;
	}
	if (newTeam == TEAM_SPEC)
	{
		return Plugin_Continue;
	}
	if (!CanJoin(client, newTeam, true))
	{
		return Plugin_Stop;
	}
	g_iClientTeam[client] = newTeam;
	return Plugin_Continue;
}

/* Admin Menu Functions */
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