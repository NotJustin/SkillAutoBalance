# SkillAutoBalance
A configurable automated team manager.<br>
[Thread on Alliedmods](https://forums.alliedmods.net/showthread.php?t=316478)

#### Table of Contents
[Credits/Inspiration](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#credits--inspiration)<br>
[Changelog](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#changelog)<br>
[Installation](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#installation)<br>
[ConVars](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#convars)<br>
[Dependencies](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#dependencies)<br>
[Compatible Plugins](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#compatible-plugins)<br>
[Bugs](https://github.com/NotJustin/SkillAutoBalance/blob/master/README.md#bugs)<br>

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

### Installation
Extract this repository into your ./csgo/addons/sourcemod/ directory.
Compile it.
Put the compiled plugin in your plugins directory.

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

sab_forcebalance (boolean | default 0)
"Add 'force balance' to 'server commands' in generic admin menu"

sab_forcejointeam (int | min 0 max 2 default 0)
"0 = Disabled, 1 = Optional (!settings), 2 = Forced. Force clients to join a team upon connecting to the server. Always enabled if both sab_chatchangeteam and sab_teammenu are disabled"

sab_keepplayersalive (boolean | default 1)
"Living players are kept alive when their teams are changed"

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

sab_scoretype (int | min 0 max 6 default 0)
"Formula used to determine player 'skill'. 0 = K/D, 1 = K/D + K/10 - D/20, 2 = K^2/D, 3 = gameME rank, 4 = RankME, 5 = LVL Ranks, 6 = NCRPG" (note NCRPG does not work yet. Maybe soon)

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
Third party include files you need in order to compile are:
 * gameme.inc
 * kento_rankme/rankme.inc
 * lvl_ranks.inc
 * ncrpg_Constants.inc
 * ncrpg_XP_Credits.inc
 
### Compatible Plugins
[gameME](https://www.gameme.com/)<br>
[RankMe Kento Edition](https://forums.alliedmods.net/showthread.php?t=290063) currently untested, need confirmation that this works<br>
[LVL Ranks](https://github.com/levelsranks/levels-ranks-core) currently untested, need confirmation that this works

### Bugs

No none bugs at the moment :D
