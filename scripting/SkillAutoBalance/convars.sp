ConVar
	cvar_AutoTeamBalance,
	cvar_LimitTeams,
	cvar_MaxRounds,
	cvar_NoBalanceLastNMinutes,
	cvar_NoBalanceLastNRounds,
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
	cvar_ForceJoinTeam,
	cvar_ChatChangeTeam,
	cvar_SetTeam,
	cvar_ForceBalance,
	cvar_BlockTeamSwitch,
	cvar_KeepPlayersAlive,
	cvar_EnablePlayerTeamMessage,
	cvar_BotsArePlayers,
	cvar_MaxTeamSize,
	cvar_ScoreType
;

void CreateConVars()
{
	cvar_AutoTeamBalance = FindConVar("mp_autoteambalance");
	cvar_GraceTime = FindConVar("mp_join_grace_time");
	cvar_LimitTeams = FindConVar("mp_limitteams");
	cvar_MaxRounds = FindConVar("mp_maxrounds");
	cvar_RoundRestartDelay = FindConVar("mp_round_restart_delay");
	cvar_RoundTime = FindConVar("mp_roundtime");

	cvar_NoBalanceLastNMinutes = CreateConVar("sab_nobalancelastnminutes", "0", "0 = Disabled. Otherwise, this is the amount of time remaining before the map ends where balancing is turned off.");
	cvar_NoBalanceLastNRounds = CreateConVar("sab_nobalancelastnrounds", "0", "0 = Disabled. Otherwise, this is the amount of rounds remaining before the map ends where balancing is turned off.");

	cvar_BalanceAfterNRounds = CreateConVar("sab_balanceafternrounds", "0", "0 = Disabled. Otherwise, after map change balance teams when 'N' rounds pass. Then balance based on team win streaks", _, true, 0.0);
	cvar_BalanceAfterNPlayersChange = CreateConVar("sab_balanceafternplayerschange", "0", "0 = Disabled. Otherwise, balance  teams when 'N' players join/leave the server. Requires sab_balanceafternrounds to be enabled", _, true, 0.0);
	cvar_BalanceEveryRound = CreateConVar("sab_balanceeveryround", "0", "If enabled, teams will be rebalanced at the end of every round", _, true, 0.0, true, 1.0);
	cvar_BlockTeamSwitch = CreateConVar("sab_blockteamswitch", "0", "0 = Don't block. 1 = Block, can join spectate, must rejoin same team. 2 = Block completely (also disables teammenu and chatchangeteam commands like !join !spec)", _, true, 0.0, true, 2.0);
	cvar_BotsArePlayers = CreateConVar("sab_botsareplayers", "0", "When teams are being balanced, 1 = Bots are players (bots have points/KDR), 0 = Bots are outliers (bots do not have points/KDR)", _, true, 0.0, true, 1.0);
	cvar_ChatChangeTeam = CreateConVar("sab_chatchangeteam", "0", "Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)", _, true, 0.0, true, 1.0);
	cvar_DecayAmount = CreateConVar("sab_decayamount", "1.5", "The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur.", _, true, 1.0);
	cvar_EnablePlayerTeamMessage = CreateConVar("sab_enableplayerteammessage", "0", "Show the messages in chat when a player switches team?", _, true, 0.0, true, 1.0);
	cvar_ForceBalance = CreateConVar("sab_forcebalance", "0", "Add 'force balance' to 'server commands' in generic admin menu", _, true, 0.0, true, 1.0);
	cvar_ForceJoinTeam = CreateConVar("sab_forcejointeam", "0", "0 = Disabled, 1 = Optional (!settings), 2 = Forced. Force clients to join a team upon connecting to the server. Always enabled if both sab_chatchangeteam and sab_teammenu are disabled", _, true, 0.0, true, 2.0);
	cvar_KeepPlayersAlive = CreateConVar("sab_keepplayersalive", "1", "Living players are kept alive when their teams are changed", _, true, 0.0, true, 1.0);
	cvar_MaxTeamSize = CreateConVar("sab_maxteamsize", "0", "0 = Unlimited. Max players allowed on each team. If both teams reach this amount, new non-admin players are kicked. Only works if sab_blockteamswitch is 2.", _, true, 0.0);
	cvar_MinPlayers = CreateConVar("sab_minplayers", "7", "The amount of players not in spectate must be at least this number for a balance to occur", _, true, 2.0);
	cvar_MinStreak = CreateConVar("sab_minstreak", "6", "Amount of wins in a row a team needs before autobalance occurs", _, true, 0.0);
	cvar_Scale = CreateConVar("sab_scale", "1.5", "Value to multiply IQR by. If your points have low spread keep this number. If your points have high spread change this to a lower number, like 0.5", _, true, 0.1);
	cvar_ScoreType = CreateConVar("sab_scoretype", "0", "0 = Auto detect scoretype. Only change this if you have multiple types loaded. 1 = gameME, 2 = HLstatsX, 3 = Kento-RankMe, 4 = LevelsRanks, 5 = NCRPG, 6 = SABRating, 7 = SMRPG", _, true, 0.0, true, 7.0);
	cvar_SetTeam = CreateConVar("sab_setteam", "0", "Add 'set player team' to 'player commands' in generic admin menu", _, true, 0.0, true, 1.0);
	cvar_TeamMenu = CreateConVar("sab_teammenu", "1", "Whether to enable or disable the join team menu.", _, true, 0.0, true, 1.0);
	cvar_UseDecay = CreateConVar("sab_usedecay", "1", "If 1, subtract sab_decayamount from a team's streak when they lose instead of setting their streak to 0", _, true, 0.0, true, 1.0);
}

void AddChangeHooks()
{
	cvar_ForceBalance.AddChangeHook(UpdateForceBalance);
	cvar_SetTeam.AddChangeHook(UpdateSetTeam);
	cvar_TeamMenu.AddChangeHook(UpdateTeamMenu);
	cvar_BlockTeamSwitch.AddChangeHook(UpdateBlockTeamSwitch);
	cvar_AutoTeamBalance.AddChangeHook(UpdateAutoTeamBalance);
	cvar_LimitTeams.AddChangeHook(UpdateLimitTeams);
	cvar_ScoreType.AddChangeHook(UpdateScoreType);
}