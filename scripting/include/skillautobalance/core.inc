#if defined _skillautobalance_core_included
	#endinput
#endif
#define _skillautobalance_core_included
#define SAB_PLUGIN_NAME "sab-core"
#define SAB_PLUGIN_FILE SAB_PLUGIN_NAME ... ".smx"
#define SAB_PLUGIN_AUTHOR "Justin (ff)"
#define SAB_PLUGIN_DESCRIPTION "A configurable automated team manager"
#define SAB_PLUGIN_VERSION "4.1.3"
#define SAB_PLUGIN_URL "https://steamcommunity.com/id/NameNotJustin/"

#undef REQUIRE_PLUGIN
#include <gameme>
#include <hlstatsx_api>
#include <kento_rankme/rankme>
#include <lvl_ranks>
#include <NCIncs/nc_rpg.inc>
#include <kpr_rating>
#include <smrpg>
#include <skillautobalance/admin>
#include <skillautobalance/blockteams>
#define REQUIRE_PLUGIN

#define CHECKSCORE_DELAY 1.0

/* SAB_GetClientScoreErrors */
#define SAB_ClientIsInvalid -4.0
#define SAB_ClientIsServer -3.0
#define SAB_ClientIsNotInGame -2.0
#define SAB_ClientIsMissingScore -1.0

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
	ScoreType_KPRRating,
	ScoreType_SMRPG
}

/**
 * Called when a client is pacified (cannot shoot or take damage).
 *
 * @param client				Client who is pacified.
 */
forward void SAB_OnClientPacified(int client);

/**
 * Called when a client's team is changed.
 *
 * @param client				Client whose team has changed.
 * @param team					The team the client has been changed to.
 * @param reason				Reason that the client's team has changed.
 */
forward void SAB_OnClientTeamChanged(int client, int team, char reason[50]);

/**
 * Called when a team balance is triggered in SkillAutoBalance.
 *
 * @param sortedPlayers			Arraylist of players, in sorted order.
 * @param reason				The reason why the balance is occurring.
 */
forward void SAB_OnSkillBalance(ArrayList &sortedPlayers, char reason[50]);

/**
 * Notify skillautobalance to perform a team balance at round end.
 * The plugin using this native is responsible for determining if balance is needed.
 *
 * @param reason				The reason that the team balance is occurring.
 */
native void SAB_Balance(char reason[50]);

/**
 * Retrieves the client's score. Depends on what SAB_ScoreType is active.
 *
 * @param client				Client whose score you are retrieving.
 * @return						The client's score. Negative number on error. See SAB_GetClientScoreErrors defines.
 */
native float SAB_GetClientScore(int client);

/**
 * Changes a client's team according to how it would be changed with SkillAutoBalance.
 * This will only change their team after round end.
 * If there is a skill balance, this will cancel.
 *
 * @param client				Client whose team will be changed.
 * @param team					The team the client will be changed to.
 * @param reason				The reason the client's team will be changed.
 */
native void SAB_SwapPlayer(int client, int team, char reason[50] = "Client Skill Balance");

public SharedPlugin __pl_skillautobalance_core = 
{
	name = SAB_PLUGIN_NAME,
	file = SAB_PLUGIN_FILE,
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
}