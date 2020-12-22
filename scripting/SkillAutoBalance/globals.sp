#define SAB_PLUGIN_NAME "SkillAutoBalance" ... SAB_PLUGIN_VARIANT
#define SAB_PLUGIN_AUTHOR "Justin (ff)"
#define SAB_PLUGIN_DESCRIPTION "A configurable automated team manager"
#define SAB_PLUGIN_VERSION "3.2.3"
#define SAB_PLUGIN_URL "https://steamcommunity.com/id/NameNotJustin/"

#define UNASSIGNED 0
#define TEAM_SPEC 1
#define TEAM_T 2
#define TEAM_CT 3

#define CHECKSCORE_DELAY 1.0

bool
	g_iClientScoreUpdated[MAXPLAYERS + 1] = {false, false, ...},
	g_iClientPostAdminCheck[MAXPLAYERS + 1] = {false, false, ...},
	g_iClientConnectFull[MAXPLAYERS + 1] = {false, false, ...},
	g_AllowSpawn = true,
	g_ForceBalance,
	g_Balancing,
	g_iClientFrozen[MAXPLAYERS + 1],
	g_iClientOutlier[MAXPLAYERS + 1],
	g_iClientForceJoin[MAXPLAYERS + 1],
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
	cvar_KeepPlayersAlive,
	cvar_EnablePlayerTeamMessage,
	cvar_BotsArePlayers,
	cvar_MaxTeamSize
;

float
	g_iClientScore[MAXPLAYERS + 1],
	g_iStreak[2],
	g_LastAverageScore = 1000.0
;

Handle g_hForceSpawn;

int
	g_PlayerCount = 0,
	g_PlayerCountChange = 0,
	g_RoundCount = 0,
	g_iClient[MAXPLAYERS - 1] = {1, 2, ...},
	g_iClientTeam[MAXPLAYERS + 1],
	g_iClientForceJoinPreference[MAXPLAYERS + 1]
;