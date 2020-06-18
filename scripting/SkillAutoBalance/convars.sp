void CreateConVars()
{
	cvar_BalanceAfterNRounds = CreateConVar("sab_balanceafternrounds", "0", "0 = Disabled. Otherwise, after map change balance teams when 'N' rounds pass. Then balance based on team win streaks", _, true, 0.0);
	cvar_BalanceAfterNPlayersChange = CreateConVar("sab_balanceafternplayerschange", "0", "0 = Disabled. Otherwise, balance  teams when 'N' players join/leave the server. Requires sab_balanceafternrounds to be enabled", _, true, 0.0);
	cvar_BalanceEveryRound = CreateConVar("sab_balanceeveryround", "0", "If enabled, teams will be rebalanced at the end of every round", _, true, 0.0, true, 1.0);
	cvar_BlockTeamSwitch = CreateConVar("sab_blockteamswitch", "0", "0 = Don't block. 1 = Block, can join spectate, must rejoin same team. 2 = Block completely (also disables teammenu and chatchangeteam commands like !join !spec)", _, true, 0.0, true, 2.0);
	cvar_BotsArePlayers = CreateConVar("sab_botsareplayers", "0", "When teams are being balanced, 1 = Bots are players (bots have points/KDR), 0 = Bots are outliers (bots do not have points/KDR)", _, true, 0.0, true, 1.0);
	cvar_ChatChangeTeam = CreateConVar("sab_chatchangeteam", "0", "Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)", _, true, 0.0, true, 1.0);
	cvar_DecayAmount = CreateConVar("sab_decayamount", "1.5", "The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur.", _, true, 1.0);
	cvar_DisplayChatMessages = CreateConVar("sab_displaychatmessages", "1", "Allow plugin to display messages in the chat", _, true, 0.0, true, 1.0);
	cvar_EnablePlayerTeamMessage = CreateConVar("sab_enableplayerteammessage", "0", "Show the messages in chat when a player switches team?", _, true, 0.0, true, 1.0);
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
	cvar_Scramble = CreateConVar("sab_scramble", "0", "Randomize teams instead of using a skill formula", _, true, 0.0, true, 1.0);
	cvar_SetTeam = CreateConVar("sab_setteam", "0", "Add 'set player team' to 'player commands' in generic admin menu", _, true, 0.0, true, 1.0);
	cvar_TeamMenu = CreateConVar("sab_teammenu", "1", "Whether to enable or disable the join team menu.", _, true, 0.0, true, 1.0);
	cvar_UseDecay = CreateConVar("sab_usedecay", "1", "If 1, subtract sab_decayamount from a team's streak when they lose instead of setting their streak to 0", _, true, 0.0, true, 1.0);
}

void AddChangeHooks()
{
	cvar_ForceBalance.AddChangeHook(UpdateForceBalance);
	cvar_MessageColor.AddChangeHook(UpdateMessageColor);
	cvar_MessageType.AddChangeHook(UpdateMessageType);
	cvar_Prefix.AddChangeHook(UpdatePrefix);
	cvar_PrefixColor.AddChangeHook(UpdatePrefixColor);
	cvar_SetTeam.AddChangeHook(UpdateSetTeam);
	cvar_TeamMenu.AddChangeHook(UpdateTeamMenu);
	cvar_BlockTeamSwitch.AddChangeHook(UpdateBlockTeamSwitch);
}