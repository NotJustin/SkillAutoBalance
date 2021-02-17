#if defined _skillautobalance_blockteams_included
	#endinput
#endif
#define _skillautobalance_blockteams_included

enum SABJoinTeamResult
{
	SAB_NewTeamHasMorePlayers = 0,		/**< The team that client tries to join has too many players. */
	SAB_MustJoinPreviousTeam,			/**< The client must join the team they were previously on. */
	SAB_JoinTeamSuccess					/**< The client successfully joined the team they chose. */
}

/**
 * Called when a client returns from being AFK and is moved to a team.
 *
 * @param client					Client whose team has changed.
 */
forward void SAB_OnClientAFKReturn(int client);

/**
 * Called when a client uses the join/play command.
 *
 * @param client				Client who used command.
 * @param success				Whether the team change was successful or not.
 */
forward void SAB_OnClientJoinCommand(int client, bool success);

/**
 * Called when OnClientPostAdminCheck and the event "player_connect_full" both occur.
 *
 * @param client				Client who is initialized.
 * @param teamMenuEnabled		Whether the team menu is enabled or not.
 * @param autoJoin				Whether this plugin will automatically place the client on a team or not.
 * @param autoJoinSuccess		If autoJoin is true, was the client successfully placed on a team?
 */
forward void SAB_OnClientInitialized(int client, bool teamMenuEnabled, bool autoJoin, bool autoJoinSuccess);

/**
 * Called when a client tries to join a team through the team menu.
 * 
 * @param client 				Client who tried to use the team menu.
 * @param result				The result of the command (either success or reason for failure).
 */
forward void SAB_OnClientJoinTeam(int client, SABJoinTeamResult result);

/**
 * Called when a client will be kicked from the server because the teams are full.
 *
 * @param client				Client who will be kicked.
 * @param admin				Whether the client is admin or not. If they are admin, they are not kicked.
 */
forward void SAB_OnClientKick(int client, bool admin);

public SharedPlugin __pl_skillautobalance_blockteams = 
{
	name = "sab-blockteams",
	file = "sab-blockteams.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
}