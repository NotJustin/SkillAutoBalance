#if defined _skillautobalance_included
	#endinput
#endif
#define _skillautobalance_included
#define SAB_PLUGIN_NAME "skillautobalance"
#define SAB_PLUGIN_FILE SAB_PLUGIN_NAME ... ".smx"
#define SAB_PLUGIN_AUTHOR "Justin (ff)"
#define SAB_PLUGIN_DESCRIPTION "A configurable automated team manager"
#define SAB_PLUGIN_VERSION "4.0.0"
#define SAB_PLUGIN_URL "https://steamcommunity.com/id/NameNotJustin/"

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <afk_manager>
#include <gameme>
#include <hlstatsx_api>
#include <kento_rankme/rankme>
#include <lvl_ranks>
#include <NCIncs/nc_rpg.inc>
#include <sab_rating>
#include <smrpg>
#define REQUIRE_PLUGIN

#define CHECKSCORE_DELAY 1.0

enum SABMenuSetTeamFailReason
{
	SAB_MenuSetTeamClientNotFound = 0,	/**< The target cannot be found. */
	SAB_MenuSetTeamCannotTarget			/**< The client cannot target this player. */
}

enum SABJoinTeamResult
{
	SAB_NewTeamHasMorePlayers = 0,		/**< The team that client tries to join has too many players. */
	SAB_MustJoinPreviousTeam,			/**< The client must join the team they were previously on. */
	SAB_JoinTeamSuccess					/**< The client successfully joined the team they chose. */
}

enum SABSetTeamResult
{
	SAB_SetTeamIncorrectUsage = 0,		/**< Invalid usage of the command. */
	SAB_SetTeamClientNotFound,			/**< Targetted client was not found. */
	SAB_SetTeamSuccess					/**< Target's team has been swapped. */
}

enum SABChangeTeamReason
{
	SAB_AdminSetTeam = 0,				/**< Team changed by admin. */
	SAB_SkillBalance,					/**< Team changed due to skill balance */
	SAB_AutoJoin						/**< Team changed automatically. */
}

enum SABBalanceReason
{
	SAB_Forced = 0,						/**< Triggered by admin. */
	SAB_Uneven,							/**< Teams were uneven. */
	SAB_EveryRound,						/**< Teams are balanced every round. */
	SAB_T_Streak,						/**< The terrorists surpassed the minimum win streak value. */
	SAB_CT_Streak,						/**< The counter-terrorists surpassed the minimum win streak value. */
	SAB_AfterNRounds,					/**< Teams are balanced after the first N rounds of the map. */
	SAB_AfterNPlayersChange,			/**< Teams are balanced after N players join or leave the server. */
	SAB_NoBalance						/**< A balance did not occur. */
}

enum SABScoreType
{
	ScoreType_Invalid = -1,
	ScoreType_Auto,
	ScoreType_gameME,
	ScoreType_HLstatsX,
	ScoreType_KentoRankMe,
	ScoreType_LevelsRanks,
	ScoreType_NCRPG,
	ScoreType_SABRating,
	ScoreType_SMRPG
}

/**
* Called when an admin attempts to select a client by adminmenu and results in failure.
*
* param client				Client who used command.
* param target				Client who was selected.
* param reason				Reason that the target could not be selected.
*
* noreturn
**/
forward void SAB_OnAdminMenuClientSelectFail(int client, int target, SABMenuSetTeamFailReason reason);

/**
* Called when an admin attempts to select a client by adminmenu and results in failure.
*
* param client				Client who used command.
* param target				Client who was selected.
* param team				The team the target was to be changed to.
* param reason				Reason that the target could not be selected.
*
* noreturn
**/
forward void SAB_OnAdminMenuTeamSelectFail(int client, int target, int team, SABMenuSetTeamFailReason reason);

/**
* Called when the force balance command is used.
*
* param client				Client who used command.
*
* noreturn
**/
forward void SAB_OnBalanceCommand(int client);

/**
* Called when a client returns from being AFK and is moved to a team.
*
* param client				Client whose team has changed.
*
* noreturn
**/
forward void SAB_OnClientAFKReturn(int client);

/**
* Called when a client uses the join/play command.
*
* param client				Client who used command.
* param success				Whether the team change was successful or not.
*
* noreturn
**/
forward void SAB_OnClientJoinCommand(int client, bool success);

/**
* Called when a client will be kicked from the server because the teams are full.
*
* param client				Client who will be kicked.
* param admin				Whether the client is admin or not. If they are admin, they are not kicked.
*
* noreturn
**/
forward void SAB_OnClientKick(int client, bool admin);

/**
* Called when a client is pacified (cannot shoot or take damage).
*
* param client				Client who is pacified.
*
* noreturn
**/
forward void SAB_OnClientPacified(int client);

/**
* Called when a client's team is changed.
*
* param client				Client whose team has changed.
* param team				The team the client has been changed to.
* param reason				Reason that the client's team has changed.
*
* noreturn
**/
forward void SAB_OnClientTeamChanged(int client, int team, SABChangeTeamReason reason);

/**
* Called when an admin sets a player's team.
*
* param client				Client who used command.
* param target				Client whose team is being set.
* param result				The result of the command (either success or reason for failure).
*
* noreturn
**/
forward void SAB_OnSetTeam(int client, int target, SABSetTeamResult result);

/**
* Called when a team balance is triggered in SkillAutoBalance.
*
* param reason				Reason that the balance is occurring.
*
* noreturn
**/
forward void SAB_OnSkillBalance(SABBalanceReason reason);

/**
* Called when OnClientPostAdminCheck and the event "player_connect_full" both occur.
*
* param client				Client who is initialized.
* param teamMenuEnabled		Whether the team menu is enabled or not.
* param autoJoin			Whether this plugin will automatically place the client on a team or not.
* param autoJoinSuccess		If autoJoin is true, was the client successfully placed on a team?
**/
forward void SAB_OnClientInitialized(int client, bool teamMenuEnabled, bool autoJoin, bool autoJoinSuccess);

/**
* Called when a client tries to join a team through the team menu.
* 
* param client 				Client who tried to use the team menu.
* param result				The result of the command (either success or reason for failure).
*
* noreturn
**/
forward void SAB_OnClientJoinTeam(int client, SABJoinTeamResult result);

public SharedPlugin __pl_skillautobalance = 
{
	name = SAB_PLUGIN_NAME,
	file = SAB_PLUGIN_FILE,
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
}