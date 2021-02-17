#if defined _skillautobalance_admin_included
	#endinput
#endif
#define _skillautobalance_admin_included

enum SABMenuSetTeamFailReason
{
	SAB_MenuSetTeamClientNotFound = 0,	/**< The target cannot be found. */
	SAB_MenuSetTeamCannotTarget			/**< The client cannot target this player. */
}

enum SABSetTeamResult
{
	SAB_SetTeamIncorrectUsage = 0,		/**< Invalid usage of the command. */
	SAB_SetTeamClientNotFound,			/**< Targetted client was not found. */
	SAB_SetTeamSuccess					/**< Target's team has been swapped. */
}

/**
 * Called when an admin attempts to select a client by adminmenu and results in failure.
 *
 * @param client				Client who used command.
 * @param target				Client who was selected.
 * @param reason				Reason that the target could not be selected.
 */
forward void SAB_OnAdminMenuClientSelectFail(int client, int target, SABMenuSetTeamFailReason reason);

/**
 * Called when an admin attempts to select a client by adminmenu and results in failure.
 *
 * @param client				Client who used command.
 * @param target				Client who was selected.
 * @param team					The team the target was to be changed to.
 * @param reason				Reason that the target could not be selected.
 */
forward void SAB_OnAdminMenuTeamSelectFail(int client, int target, int team, SABMenuSetTeamFailReason reason);

/**
 * Called when the force balance command is used.
 *
 * @param client				Client who used command.
 */
forward void SAB_OnBalanceCommand(int client);

/**
 * Called when an admin sets a player's team.
 *
 * @param client				Client who used command.
 * @param target				Client whose team is being set.
 * @param result				The result of the command (either success or reason for failure).
 */
forward void SAB_OnSetTeam(int client, int target, SABSetTeamResult result);

public SharedPlugin __pl_skillautobalance_admin = 
{
	name = "sab-admin",
	file = "sab-admin.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
}