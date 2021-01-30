#include <sourcemod>
#include <skillautobalance>

#pragma newdecls required
#pragma semicolon 1

#define SWAP_REASON_SIZE 3
#define TEAMCHANGE_RESULT_SIZE 3
#define JOINTEAMATTEMPT_RESULT_SIZE 2
#define MENUFAIL_REASON_SIZE 2

public Plugin myinfo =
{
	name = "skillautobalance messages",
	author = SAB_PLUGIN_AUTHOR,
	description = "Displays messages in chat corresponding to this plugin's events.",
	version = "1.0.0",
	url = SAB_PLUGIN_URL
}

StringMap colors;

char
	joinTeamFailReasons[JOINTEAMATTEMPT_RESULT_SIZE][50] = {"Team Has More Players", "Must Join Previous Team"},
	menuSwapTeamFailReasons[MENUFAIL_REASON_SIZE][50] = {"Client Not Found", "Cannot Target Player"},
	swapTeamReasons[SWAP_REASON_SIZE][50] = {"Admin Join", "Client Skill Balance", "Auto Join"},
	teamChangeResults[TEAMCHANGE_RESULT_SIZE][50] = {"Incorrect SetTeam Usage", "Client Not Found", "Admin Client Swapped"},
	g_MessageColor[4],
	g_PrefixColor[4],
	g_Prefix[20]
;

ConVar
	cvar_MessageType,
	cvar_MessageColor,
	cvar_Prefix,
	cvar_PrefixColor
;

public void OnPluginStart()
{
	InitColorStringMap();

	HookEvent("round_start", Event_RoundStart);

	cvar_MessageColor = CreateConVar("sab_messagecolor", "white", "See sab_messagetype for info");
	cvar_MessageType = CreateConVar("sab_messagetype", "0", "How this plugin's messages will be colored in chat. 0 = no color, 1 = color only prefix with sab_prefixcolor, 2 = color entire message with sab_messagecolor, 3 = color prefix and message with both sab_prefixcolor and sab_messagecolor", _, true, 0.0, true, 3.0);
	cvar_Prefix = CreateConVar("sab_prefix", "[SAB]", "The prefix for messages this plugin writes in the server");
	cvar_PrefixColor = CreateConVar("sab_prefixcolor", "white", "See sab_messagetype for info");

	cvar_MessageColor.AddChangeHook(UpdateMessageColor);
	cvar_MessageType.AddChangeHook(UpdateMessageType);
	cvar_Prefix.AddChangeHook(UpdatePrefix);
	cvar_PrefixColor.AddChangeHook(UpdatePrefixColor);

	LoadTranslations("skillautobalance.phrases");
	LoadTranslations("common.phrases");

	AutoExecConfig(true, "SkillAutoBalance-Messages");
}

public void OnConfigsExecuted()
{
	char str[1];
	UpdateMessageColor(cvar_MessageColor, str, str);
	UpdateMessageType(cvar_MessageType, str, str);
	UpdatePrefix(cvar_Prefix, str, str);
	UpdatePrefixColor(cvar_PrefixColor, str, str);
}

void UpdateMessageColor(ConVar convar, char [] oldValue, char [] newValue)
{
	char sMessageColor[20];
	GetConVarString(convar, sMessageColor, sizeof(sMessageColor));
	int messageType = cvar_MessageType.IntValue;
	if (messageType == 0 || messageType == 1)
	{
		g_MessageColor = "\x01";
	}
	else if(messageType == 2 || messageType == 3)
	{
		SetColor(g_MessageColor, sMessageColor);
	}
}

void UpdateMessageType(ConVar convar, char [] oldValue, char [] newValue)
{
	char str[20];
	GetConVarString(cvar_MessageColor, str, sizeof(str));
	UpdateMessageColor(cvar_MessageColor, str, str);
	str[0] = '\0';
	GetConVarString(cvar_PrefixColor, str, sizeof(str));
	UpdatePrefixColor(cvar_PrefixColor, str, str);
}

void UpdatePrefix(ConVar convar, char [] oldValue, char [] newValue)
{
	GetConVarString(convar, g_Prefix, sizeof(g_Prefix));
}

void UpdatePrefixColor(ConVar convar, char [] oldValue, char [] newValue)
{
	char sPrefixColor[20];
	GetConVarString(convar, sPrefixColor, sizeof(sPrefixColor));
	int messageType = cvar_MessageType.IntValue;
	if (messageType == 0 || messageType == 2)
	{
		g_PrefixColor = "\x01";
	}
	else if(messageType == 1 || messageType == 3)
	{
		SetColor(g_PrefixColor, sPrefixColor);
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrintHowToJoinForSpectators();
}

Action PrintHowToJoinForSpectators()
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if (IsClientInGame(client))
		{
			int team = GetClientTeam(client);
			if (team != CS_TEAM_T && team != CS_TEAM_CT)
			{
				ColorPrintToChat(client, "Team Menu Disabled");
			}
		}
	}
}

void InitColorStringMap()
{
	colors = new StringMap();
	colors.SetString("red", "\x07");
	colors.SetString("white", "\x01");
	colors.SetString("lightred", "\x0F");
	colors.SetString("darkred", "\x02");
	colors.SetString("bluegrey", "\x0A");
	colors.SetString("blue", "\x0B");
	colors.SetString("darkblue", "\x0C");
	colors.SetString("orchid", "\x0E");
	colors.SetString("yellow", "\x09");
	colors.SetString("gold", "\x10");
	colors.SetString("lightgreen", "\x05");
	colors.SetString("green", "\x04");
	colors.SetString("lime", "\x06");
	colors.SetString("grey", "\x08");
	colors.SetString("grey2", "\x0D");
}
void SetColor(char str[4], char color[20])
{
	if (!colors.GetString(color, str, sizeof(str)))
	{
		str = "\x01";
	}
}
void AppendDataToString(char str[255])
{
	StrCat(str, sizeof(str), g_PrefixColor);
	StrCat(str, sizeof(str), g_Prefix);
	StrCat(str, sizeof(str), " ");
	StrCat(str, sizeof(str), g_MessageColor);
	StrCat(str, sizeof(str), "%t");
}
void ColorPrintToChat(int client, char phrase[50])
{
	char str[255] = " ";
	AppendDataToString(str);
	PrintToChat(client, str, phrase);
}
void ColorPrintToChatAll(char phrase[50])
{
	char str[255] = " ";
	AppendDataToString(str);
	PrintToChatAll(str, phrase);
}
void PrefixPrintToServer(char phrase[50])
{
	char str[255] = " ";
	AppendDataToString(str);
	PrintToServer(str, phrase);
}

public void SAB_OnAdminMenuTeamSelect(int client, int target, int team, bool success)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (success)
		{
			ColorPrintToChat(client, "Admin Client Swapped");
		}
		else
		{
			ColorPrintToChat(client, "Client Not Found");
		}
	}
	else if (!client)
	{
		if (success)
		{
			PrefixPrintToServer("Admin Client Swapped");
		}
		else
		{
			PrefixPrintToServer("Client Not Found");
		}
	}
}

public void SAB_OnAdminMenuClientSelectFail(int client, int target, SABMenuSetTeamFailReason reason)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, menuSwapTeamFailReasons[reason]);
	}
}

public void SAB_OnBalanceCommand(int client)
{
	if (!client)
	{
		PrefixPrintToServer("Admin Force Balance");
	}
	else if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, "Admin Force Balance");
	}
}

public void SAB_OnClientAFKReturn(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, "AFK Return");
	}
}

public void SAB_OnSetTeam(int client, int target, SABSetTeamResult result)
{
	if (!client)
	{
		PrefixPrintToServer(teamChangeResults[result]);
	}
	else if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, teamChangeResults[result]);
	}
}

public void SAB_OnClientTeamChanged(int client, int team, SABChangeTeamReason reason)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, swapTeamReasons[reason]);
	}
}

public void SAB_OnClientPacified(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, "Pacified Client");
	}
}

public void SAB_OnSkillBalance(SABBalanceReason reason)
{
	ColorPrintToChatAll("Global Skill Balance");
}

public void SAB_OnClientJoinTeam(int client, SABJoinTeamResult result)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && result != SAB_JoinTeamSuccess)
	{
		ColorPrintToChat(client, joinTeamFailReasons[result]);
	}
}

public void SAB_OnClientJoinCommand(int client, bool success)
{
	if (!success && client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		ColorPrintToChat(client, "Teams Are Full");
	}
}

public void SAB_OnClientInitialized(int client, bool teamMenuEnabled, bool autoJoin, bool autoJoinSuccess)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (!teamMenuEnabled)
		{
			ColorPrintToChat(client, "Team Menu Disabled");
		}
		if (autoJoin)
		{
			if (autoJoinSuccess)
			{
				ColorPrintToChat(client, "Auto Join");
			}
			else
			{
				ColorPrintToChat(client, "Teams Are Full");
			}
		}
	}
}

public void SAB_OnClientKick(int client, bool admin)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && admin)
	{
		ColorPrintToChat(client, "Not Kicked Because Admin");
	}
}