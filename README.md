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

### Changelog
3.0.1 - Changed sorting method when sorting by gameME or RankMe.
Using gameME, RankMe, LVL Ranks or NC RPG, get client's skill rather than their rank. This way, I can sort all of the score types in the same way.

3.0.0 - I've been making lots of minor changes to this plugin over the last month. In general, it consists of function optimization, improving code readability, adding some features and trying out various solutions to the bug I've been trying to fix for awhile now (see Bugs section).

You can see old changelog(s) at the alliedmodders thread.

### Installation
Extract this repository into your ./csgo/addons/sourcemod/ directory.
Compile it.
Put the compiled plugin in your plugins directory.

### ConVars
```
sab_blockteamswitch (boolean | default 0)
"Prevent clients from switching team. Can join spectate. Can switch if it is impossible for them to rejoin same team due to team-size"

sab_chatchangeteam (boolean | default 0)
"Enable joining teams by chat commands '!join, !play, !j, !p, !spectate, !spec, !s (no picking teams)"

sab_decayamount (float | min 1 default 1.5)
"The amount to subtract from a streak if UseDecay is true. In other words, the ratio of a team's round wins to the opposing team's must be greater than this number in order for a team balance to eventually occur"

sab_displaychatmessages (boolean | default 1) 
"Allow plugin to display messages in the chat"

sab_forcebalance (boolean | default 0)
"Add 'force balance' to 'server commands' in generic admin menu"

sab_forcejointeam (boolean | default 0)
"Force clients to join a team upon connecting to the server. If both sab_chatchangeteam and sab_teammenu are disabled, this will always be enabled (otherwise, clients cannot join a team)"

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

sab_scoretype (int | min 0 max 4 default 0)
"Formula used to determine player 'skill'. 0 = K/D, 1 = 2*K/D, 2 = K^2/D, 3 = gameME rank, 4 = RankMe rank"

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
 * nc_rpg.inc
 * lvl_ranks.inc
 
### Compatible Plugins
[gameME](https://www.gameme.com/)<br>
[RankMe Kento Edition](https://forums.alliedmods.net/showthread.php?t=290063) currently untested, need confirmation that this works<br>
NCRPG currently untested, need confirmation that this works<br>
LVL Ranks currently untested, need confirmation that this works

### Bugs

(rare) when a player joins the server, they may spawn in the opposing team's spawn. As this occurs rarely, it is difficult for me to test whether I have fixed it or not. If you notice this happens, set these convars accordingly:
 * sab_blockteamswitch 0
 * sab_forcejointeam 0
 * sab_teammenu 1
