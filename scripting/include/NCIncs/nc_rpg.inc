#if SOURCEMOD_V_MINOR<10
#error "Sourcemod need to update to version 1.10.6385"
#else
	#if SOURCEMOD_V_REV<6381
	#error "Sourcemod need to update to version 1.10.6385"
	#endif
#endif
#if defined _nc_rpg_included
	#endinput
#endif
#define _nc_rpg_included
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include "NCIncs/ncrpg_Constants"
#include "NCIncs/ncrpg_GameCheck"
#include "NCIncs/ncrpg_Effects"
#include "NCIncs/ncrpg_XP_Credits"
#include "NCIncs/ncrpg_Messages"
//#include "NCIncs/ncrpg_Messages_css"
//#include "NCIncs/ncrpg_Menu"
#include "NCIncs/ncrpg_Buffs"
#include "NCIncs/ncrpg_Skills"
#include "NCIncs/ncrpg_Damage"
#include "NCIncs/ncrpg_Configs"
#include "NCIncs/ncrpg_PrecacheDownload"

forward NCRPG_OnConnectedToDB(Handle hndl);

forward NCRPG_OnClientLoaded(int client, int count);

forward void NCRPG_OnRegisterSkills();

forward void NCRPG_OnPlayerSpawn(int client);

forward void NCRPG_OnPlayerSpawnedPost(int client);

native Handle NCRPG_GetDbHandle();

stock bool IsValidPlayer(int client, bool alive = false) {
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{		
		if(alive && !IsPlayerAlive(client))
			return false;
		
		return true;
	}
	
	return false;
}

stock bool IsValidClient(int iClient) { return (iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient) && !IsFakeClient(iClient)); }

stock bool GetClientSteamID(int client, String:auth[],int maxlen) 
{
	if(IsClientAuthorized(client))
		if(GetClientAuthId(client,AuthId_Steam2, auth, maxlen))
		{
			if(StrEqual(auth, "BOT", true))
				Format(auth, maxlen, "BOT_%N", client);
			else if(StrEqual(auth, "STEAM_ID_LAN", true))
				GetClientName(client, auth, maxlen);
			
			return true;
		}

	Format(auth, maxlen, "UNKNOWN");	
	return false;
}


stock float GetTeamRatio(int team) {
	return float(GetTeamClientCount((team == CS_TEAM_T)?CS_TEAM_CT:CS_TEAM_T))/float(GetTeamClientCount(team));
}


public SharedPlugin __pl_nc_rpg = 
{
	name = "NCRPG",
	file = "NCRPG.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_nc_rpg_SetNTVOptional()
{
	MarkNativeAsOptional("NCRPG_RegSkill");
	MarkNativeAsOptional("NCRPG_DisableSkill");
	MarkNativeAsOptional("NCRPG_IsSkillDisabled");
	MarkNativeAsOptional("NCRPG_IsValidSkill");
	MarkNativeAsOptional("NCRPG_IsValidSkillID");
	MarkNativeAsOptional("NCRPG_GetSkillMaxLevel");
	MarkNativeAsOptional("NCRPG_GetSkillName");
	MarkNativeAsOptional("NCRPG_GetSkillDesc");
	MarkNativeAsOptional("NCRPG_GetClientSkillCost");
	MarkNativeAsOptional("NCRPG_GetSkillCost");
	MarkNativeAsOptional("NCRPG_GetSkillCostSales");
	MarkNativeAsOptional("NCRPG_GetSkillCount");
	MarkNativeAsOptional("NCRPG_GetEmptySkills");
	MarkNativeAsOptional("NCRPG_FindSkillByShortname");
	MarkNativeAsOptional("NCRPG_SetSkillLevel");
	MarkNativeAsOptional("NCRPG_GetSkillLevel");
	MarkNativeAsOptional("NCRPG_SetMaxHP");
	MarkNativeAsOptional("NCRPG_GetMaxHP");
	MarkNativeAsOptional("NCRPG_SetMaxArmor");
	MarkNativeAsOptional("NCRPG_GetMaxArmor");
	MarkNativeAsOptional("NCRPG_DealDamage");
	MarkNativeAsOptional("NCRPG_FreezePlayer");
	MarkNativeAsOptional("NCRPG_SetIsPlayerFrozen");
	MarkNativeAsOptional("NCRPG_IsPlayerFrozen");
	MarkNativeAsOptional("NCRPG_SlowPlayer");
	MarkNativeAsOptional("NCRPG_SpeedPlayer");
	MarkNativeAsOptional("NCRPG_SetSlow");
	MarkNativeAsOptional("NCRPG_GetSlow");	
	MarkNativeAsOptional("NCRPG_SetPlayerSpeed");
	MarkNativeAsOptional("NCRPG_GetPlayerSpeed");
	MarkNativeAsOptional("NCRPG_SetColor");
	MarkNativeAsOptional("NCRPG_GetColor");	
	MarkNativeAsOptional("NCRPG_SetSpeed");
	MarkNativeAsOptional("NCRPG_GetSpeed");		
	MarkNativeAsOptional("NCRPG_SetMaxSpeed");
	MarkNativeAsOptional("NCRPG_GetMaxSpeed");	
	MarkNativeAsOptional("NCRPG_SetGravity");
	MarkNativeAsOptional("NCRPG_GetGravity");
	MarkNativeAsOptional("NCRPG_SetReqXP");
	MarkNativeAsOptional("NCRPG_GetReqXP");
	MarkNativeAsOptional("NCRPG_GetXP");
	MarkNativeAsOptional("NCRPG_SetXP");
	MarkNativeAsOptional("NCRPG_GetLevel");
	MarkNativeAsOptional("NCRPG_SetLevel");
	MarkNativeAsOptional("NCRPG_SetCredits");
	MarkNativeAsOptional("NCRPG_GetCredits");
	MarkNativeAsOptional("NCRPG_GiveExp");
	MarkNativeAsOptional("NCRPG_SetExp");
	MarkNativeAsOptional("NCRPG_TakeExp");
	MarkNativeAsOptional("NCRPG_ResetPlayer");
	MarkNativeAsOptional("NCRPG_ResetAllPlayers");
	MarkNativeAsOptional("NCRPG_OpenMenuMain");
	MarkNativeAsOptional("NCRPG_OpenMenuHelp");
	MarkNativeAsOptional("NCRPG_OpenMenuStats");
	MarkNativeAsOptional("NCRPG_OpenMenuPlayersInfo");
	MarkNativeAsOptional("NCRPG_LogMessage");
	MarkNativeAsOptional("NCRPG_GetDbHandle");
	MarkNativeAsOptional("NCRPG_GetGravity");
	MarkNativeAsOptional("NCRPG_SetAlpha");
	MarkNativeAsOptional("NCRPG_GetAlpha");	
	MarkNativeAsOptional("NCRPG_SetMaxAlpha");
	MarkNativeAsOptional("NCRPG_GetMaxAlpha");	
	MarkNativeAsOptional("NCRPG_SkillActivate");
	MarkNativeAsOptional("NCRPG_SkillActivated");	
	MarkNativeAsOptional("NCRPG_GetSkillShortName");	
	MarkNativeAsOptional("NCRPG_GetParamStringBySteamID");
	MarkNativeAsOptional("NCRPG_GetParamIntBySteamID");	
	MarkNativeAsOptional("NCRPG_SetParamIntBySteamID");	
	MarkNativeAsOptional("NCRPG_GiveCredits");	
	MarkNativeAsOptional("NCRPG_ChatMessage");	
	MarkNativeAsOptional("NCRPG_GiveExpBySteamID");	
	MarkNativeAsOptional("NCRPG_SetExpBySteamID");	
	MarkNativeAsOptional("NCRPG_TakeExpBySteamID");	
}
#endif