<p align="center">
 <img width="630" height="50" src="https://forums.alliedmods.net/image-proxy/bb415b212a80b7a578daa8a01733f35f7cf1b467/68747470733a2f2f63646e2e646973636f72646170702e636f6d2f6174746163686d656e74732f3639303232343333353735393231323734322f3731393634363637343932353931323137342f736b696c6c6175746f62616c616e63652e706e67"><br>
 A configurable automated team manager.<br>
 https://forums.alliedmods.net/showthread.php?p=2653016
</p><br>

#### Table of Contents
[Description](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#description)<br>
[Credits/Inspiration](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#credits--inspiration)<br>
[Changelog](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#changelog)<br>
[Installation](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#installation)<br>
[ConVars](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#convars)<br>
[Dependencies](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#dependencies)<br>
[Compatible Plugins](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#compatible-plugins)<br>
[Bugs](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#bugs)<br>

### Description
Skill Auto Balance is a simple concept. Rearrange the players on each team so that each team's skill level is approximately the same. In practice, doing this is very difficult because teams are made of random players and defining "individual skill" in team-based game modes is difficult.<br>
<br>
For that reason, this plugin is designed for a specific type of gamemode. It is meant for round-based gamemodes where the objective is to eliminate the enemy team.<br>
<br>
What this plugin does is calculate a score for each player to represent their "skill", and then assign players to each team in a way such that the sum of the player scores on each team is as close as possible - with some exceptions due to players with excessively high or low scores. The way that score is calculated depends on which version of the plugin is used. The basic version of the plugin assigns scores by each player's kill-death ratio. All other versions use scores based off of external point-systems from other plugins. There are currently 6 external plugins that Skill Auto Balance supports. Adding support for an additional plugin is as simple as fetching a player's score using a native from the plugin we want to add support for.<br>

### Credits / Inspiration
[Admin Player Team Switch and Scramble Menu by r5053](https://forums.alliedmods.net/showthread.php?p=549446)<br>
[[CS:S/GO+DoD:S] Auto Team Scrambler 2 (Updated 27-12-2012 @ DODS/CSGO) by RedSword](https://forums.alliedmods.net/showthread.php?p=1685854)<br>
[[ANY MOD] SwapTeam v1.2.6 (Updated 30/09/12) by bobbobagan](https://forums.alliedmods.net/showthread.php?p=859951)<br>
[CS:S Team Balance by dalto](https://forums.alliedmods.net/showthread.php?p=515853)<br>
[RankMe RankScramble by eyal282](https://forums.alliedmods.net/showpost.php?p=2641877&postcount=607)<br>
[Team Join Manager by GetRektByNoob](https://forums.alliedmods.net/showthread.php?p=2658904)<br>
[Block Team Changes by sdz](https://forums.alliedmods.net/showpost.php?p=2422410&postcount=2)<br>
[TeamChange Unlimited by Sheepdude](https://forums.alliedmods.net/showthread.php?p=1877187)<br>
[CSGO Auto Assign Team by SM9](https://forums.alliedmods.net/showthread.php?t=321314)

### Changelog
<details>
 <summary>Expand for changelog</summary>
3.2.4 - <br>
Properly check if a server has SourceTV before doing balance. Fixes bug where balance never occurs.<br>
Do not move players to spectate if forcejointeam is disabled. Fixes bug where teammenu disappears after a few seconds and players must wait.<br>
Only increment rounds passed after warmup ends. Balance after "n" rounds had been occurring 1 round too early.<br>
Thanks to Răzvan from alliedmodders for helping me debug and fix these issues.<br>
3.2.3 - <br>
Added cvar_MaxTeamSize. It allows you to set a maximum team size. If the team sizes reach the max, players who join and are not admin are kicked. The admins who join can only spectate.<br>
Fixed bug caused by last update, where players who teams were switched are immune for ~1 second at round start.<br>
Added translations/phrases related to the new convar.<br>
Fixed bug in issue #27 and #29<br>
Fixed bug where players can still join spectate when disabled, by adding commandlistener for spectate.<br>
<br>
3.2.2 - <br>
Fixed a bug where client scores were not being fetched properly.<br>
Fixed a bug where GetAverageScore would not iterate through all players, resulting in an abnormally low average score.<br>
Few small logic fixes.<br>
Fixed name of levelsranks plugin to be levelsranks and not levelranks (thanks penalte on alliedmods).<br>
<br>
3.2.1 - <br>
Fixed "sab_forcejointeam 1", which did not function properly.<br>
<br>
3.2.0 - <br>
Split the plugin into different versions and removed sab_scoretype. See Installation section.<br>
<br>
3.1.5 - <br>
Add HLStatsX support. Not sure if it works. Other changes in other versions, bugfixes, I'll go through commit history later and update this.<br>
<br>
3.1.1 - <br>
Bugfixes:<br>
This time, for sure, the correct amount of players will be swapped now. The bug is, there were duplicate clients being created in my list of clients. They were created after sorting. In my list of clients, there were some extra empty indices with 0's, and those 0's were being replaced with other client indices.<br>
Also fixed other broken logic related to determining which players count as outliers.<br>
<br>
3.1.0 - <br>
Bugfixes: <br>
The correct amount of players will be swapped now. (closed issues #8 and #11)<br>
Changes: <br>
ForceJoinTeam convar changed to be an int and has 3 options now (disabled: 0, optional: 1, forced: 2) <br>
Added new cvars to balance teams after map change and after a certain amount of players join/leave, or even to balance every single round.<br>
Added a scale. Basically, lower scale = more outliers.<br>
Translations updated.<br>
<br>
3.0.2 - <br>
Bugfixes:<br>
Scores are updated correctly.<br>
BalanceSkill now only occurs after all scores are updated.<br>
Disabling "teammenu" now only occurs after mapstart to prevent errors.<br>
Balance should no longer cause teams to be horribly misbalanced. (imagine making an autobalance that just makes teams worse)<br>
Spawn bug (may) be fixed after implementing "[CSGO] Auto Assign Team by SM9". Forcing players to join teams now uses ClientCommand for "jointeam". Thanks to MAMAC for showing me and both SM9+MAMAC for creating this. *I say "may" be fixed because the problem was already rare and so it is possible that I have just not seen or been notified of it happening when it does.*<br>
<br>
Changes:<br>
Sorting method combines two ideas now. I call them "closest sums" and "alternating".<br>
"Closest sums" makes the sum of points on both teams as close as possible.<br>
"Alternating" alternates players between teams as it goes down the sorted list.<br>
Read about it here: https://github.com/NotJustin/SkillAutoBalance/issues/2#issuecomment-636419874<br>
Added support for Level Ranks<br>
A fork of the plugin on github has support for NC RPG. I added but shortly after removed support because their include file has a lot of extra includes that I don't want to add as a requirement for this plugin to be installed.<br>
BlockTeamSwitch convar changed to be an int and has 3 options now (disabled: 0, enabled but can spectate: 1, enabled with no switching at all: 2)<br>
<br>
3.0.1 - Changed sorting method when sorting by gameME or RankMe.<br>
Using gameME, RankMe, LVL Ranks or NC RPG, get client's skill rather than their rank. This way, I can sort all of the score types in the same way.<br>
<br>
3.0.0 - I've been making lots of minor changes to this plugin over the last month. In general, it consists of function optimization, improving code readability, adding some features and trying out various solutions to the bug I've been trying to fix for awhile now (see Bugs section).

You can see old changelog(s) at the alliedmodders thread.
</details>

### Installation
Put the skillautobalance you want to use into your plugins directory. You only need one.<br>
Pick skillautobalance if you do not use any of the other plugins, or if you do not want to balance with those versions.<br>
Put skillautobalance.phrases.txt into your translations directory.<br>
If you want to compile it yourself, just pick the one you need from scripting. You should not need to take any of the include files if you already have the other plugin installed (eg: if you have rankme installed you should already have all of the kento_rankme includes).

### ConVars
```
sab_balanceafternplayerschange (int | min 0 default 0)
"0 = Disabled. Otherwise, balance  teams when 'N' players join/leave the server. Requires sab_balanceafternrounds to be enabled"

sab_balanceafternrounds (int | min 0 default 0)
"0 = Disabled. Otherwise, after map change balance teams when 'N' rounds pass. Then balance based on team win streaks"

sab_balanceeveryround (boolean | default 0)
"If enabled, teams will be rebalanced at the end of every round"

sab_blockteamswitch (int | min 0 max 2 default 0)
"0 = Don't block. 1 = Block, can join spectate, must rejoin same team. 2 = Block completely (also disables teammenu and chatchangeteam commands like !join !spec)"

sab_chatchangeteam (boolean | default 0)
"Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)"

sab_decayamount (float | min 1 default 1.5)
"The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur"

sab_displaychatmessages (boolean | default 1) 
"Allow plugin to display messages in the chat"

sab_enableplayerteammessage (boolean | default 0)
"Show the messages in chat when a player switches team"

sab_forcebalance (boolean | default 0)
"Add 'force balance' to 'server commands' in generic admin menu"

sab_forcejointeam (int | min 0 max 2 default 0)
"0 = Disabled, 1 = Optional (!settings), 2 = Forced. Force clients to join a team upon connecting to the server. Always enabled if both sab_chatchangeteam and sab_teammenu are disabled"

sab_keepplayersalive (boolean | default 1)
"Living players are kept alive when their teams are changed"

sab_maxteamsize (int | default 0)
"0 = Unlimited. Max players allowed on each team. If both teams reach this amount, new non-admin players are kicked. Only works if sab_blockteamswitch is 2."

sab_messagecolor (string | default white)
"See sab_messagetype for info"

sab_messagetype (int | min 0 max 3 default 0)
"How this plugin's messages will be colored in chat. 0 = no color, 1 = color only prefix with sab_prefixcolor, 2 = color entire message with sab_messagecolor, 3 = color prefix and message with both sab_prefixcolor and sab_messagecolor"

sab_minplayers (int | min 2 default 7)
"The amount of players not in spectate must be at least this number for a balance to occur"

sab_minstreak (int | min 0 default 6)
"Amount of wins in a row a team needs before autobalance occurs"

sab_prefix (string | default [SAB])
"The prefix for messages this plugin writes in the server"

sab_prefixcolor (string | default white)
"See sab_messagetype for info"

sab_scale (float | min 0.1 default 1.5)
"Value to multiply IQR by. If your points have low spread keep this number. If your points have high spread change this to a lower number, like 0.5"

sab_scramble (boolean | default 0)
"Randomize teams instead of using a skill formula"

sab_setteam (boolean | default 0)
"Add 'set player team' to 'player commands' in generic admin menu"

sab_teammenu (boolean | default 1)
"Whether to enable or disable the join team menu"

sab_usedecay (boolean | default 1)
"If 1, subtract sab_decayamount from a team's streak when they lose instead of setting their streak to 0"
```

### Dependencies
Third party include files you need in order to compile depend on what version you are using. See Installation section.
 
### Compatible Plugins
[gameME](https://www.gameme.com/)<br>
[RankMe Kento Edition](https://github.com/rogeraabbccdd/Kento-Rankme) untested<br>
[LVL Ranks](https://github.com/levelsranks/levels-ranks-core) untested<br>
[NCRPG](https://github.com/Rabb1tof/NCRPG)<br>
[SMRPG](https://github.com/peace-maker/smrpg)<br> untested
[HLStatsX](https://github.com/NomisCZ/hlstatsx-community-edition) untested

### Bugs

No bugs, as far as I know.
