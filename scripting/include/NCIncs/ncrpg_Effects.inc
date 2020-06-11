
//Beam
#define BEAMSPRITE_CSGO      "materials/sprites/laserbeam.vmt"
#define BEAMSPRITE_SOURCE    "materials/sprites/lgtning.vmt"
//Halo
#define HALOSPRITE_CSGO     "materials/sprites/halo.vmt"
#define HALOSPRITE_SOURCE   "materials/sprites/halo01.vmt"
//Glow
#define GLOWSPRITE     "materials/effects/redflare.vmt"
#define GLOWSPRITEBLUE_CSGO     "materials/effects/blueflare1.vmt"
#define GLOWSPRITEBLUE_SOURCE     "materials/effects/fluttercore.vmt"

stock int PrecacheHaloSprite() 
{
    int spriteIndex = PrecacheModel(GAMECSGO ? HALOSPRITE_CSGO : HALOSPRITE_SOURCE);

    if(spriteIndex == -1) 
    {
		SetFailState("Failed to precache HaloSprite material \"%s\"", GAMECSGO ? HALOSPRITE_CSGO : HALOSPRITE_SOURCE);
    }
    
    return spriteIndex;
}

stock int PrecacheBeamSprite() 
{
    int spriteIndex = PrecacheModel(GAMECSGO ? BEAMSPRITE_CSGO : BEAMSPRITE_SOURCE);

    if(spriteIndex == -1) 
    {
		SetFailState( "Failed to precache BeamSprite material \"%s\"", GAMECSGO ? BEAMSPRITE_CSGO : BEAMSPRITE_SOURCE);
    }
    
    return spriteIndex;
}

stock int PrecacheGlowSprite() 
{
	int spriteIndex = PrecacheModel(GLOWSPRITE);
	if(spriteIndex == -1) 
    {
		SetFailState( "Failed to precache GlowSprite material \"%s\"",GLOWSPRITE);
    }
	return spriteIndex;
}

stock int PrecacheGlowSpriteBlue() 
{
	int spriteIndex = PrecacheModel(GAMECSGO ? GLOWSPRITEBLUE_CSGO : GLOWSPRITEBLUE_SOURCE);
	if(spriteIndex == -1) 
    {
		SetFailState( "Failed to precache BlueGlowSprite material \"%s\"", GAMECSGO ? GLOWSPRITEBLUE_CSGO : GLOWSPRITEBLUE_SOURCE);
    }
	return spriteIndex;
}
/*=======================RGBA==================================*/
stock int SetPlayerAlpha(int client,int amount) {
	if(amount > 255) amount = 255;
	else if(amount < 0) amount = 0;
	SetEntityAlpha(client,amount);
	return GetPlayerAlpha(client);
}

stock int GetPlayerAlpha(int client) {
	return GetEntityAlpha(client);
}

stock int GetEntityAlpha(int index)
{
	return GetEntData(index, GetEntSendPropOffs(index, "m_clrRender", true) + 3, 1); 
}

stock int GetPlayerR(int index)
{
	return GetEntData(index, GetEntSendPropOffs(index, "m_clrRender", true), 1);
}

stock int GetPlayerG(int index)
{
	return GetEntData(index, GetEntSendPropOffs(index, "m_clrRender", true) + 1, 1); 
}

stock int GetPlayerB(int index)
{
	return GetEntData(index, GetEntSendPropOffs(index, "m_clrRender", true) + 2, 1); 
}

stock void SetPlayerColor(int index,int r,int g,int b)
{
	SetEntityRenderMode(index,RENDER_TRANSCOLOR);
	SetEntityRenderColor(index,r,g,b,GetEntityAlpha(index));  
}

// FX Distort == 14
// Render TransAdd == 5
stock void SetEntityAlpha(int index,int alpha)
{ 
	char class[32];
	GetEntityNetClass(index, class, sizeof(class) );
	//if(FindSendPropOffs(class,"m_nRenderFX")>-1){
	SetEntityRenderMode(index,RENDER_TRANSCOLOR);
	SetEntityRenderColor(index,GetPlayerR(index),GetPlayerG(index),GetPlayerB(index),alpha);
	//}
	//else LogError("m_nRenderFX error");
}

/*====================================================================*/
stock int PrecacheParticle(const char[] sParticleName)
{
	return PrecacheGeneric(sParticleName,true);
}


stock void PrecacheParticleEffect(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if (table == INVALID_STRING_TABLE) table = FindStringTable("ParticleEffectNames");
	bool save = LockStringTables(false);
	AddToStringTable(table, sEffectName);
	LockStringTables(save);
}

stock int GetParticleEffectIndex(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;
	if (table == INVALID_STRING_TABLE) table = FindStringTable("ParticleEffectNames");
	int iIndex = FindStringIndex(table, sEffectName);
	if (iIndex != INVALID_STRING_INDEX) return iIndex;
	return 0;
}


/**
 * Create Light
 * 
 * Spawns a light_dynamic at a fixed position.
 * 
 * @param float fPos[3] Position to spawn the light at
 * @param char color RGBA value of the color like "255 255 255 255"
 * @param char style See http://developer.valvesoftware.com/wiki/Light under "Appearances"
 * @param distance how far the light stretches
 * 
 * @returns the entinty index of the light or -1 if there was none created
 */
 
stock int NCRPG_CreateLight(const float fPos[3], const char[] color, const char[] style, const float distance)
{
    int light = CreateEntityByName("light_dynamic");
    if (IsValidEdict(light))
    {
        DispatchKeyValue(light, "_light", color);
        DispatchKeyValue(light, "brightness", "1");
        
        // Not so sure how this changes the looks. 
        DispatchKeyValueFloat(light, "spotlight_radius", 32.0);
        DispatchKeyValueFloat(light, "distance", distance);
        DispatchKeyValue(light, "style", style);
        DispatchSpawn(light);
        AcceptEntityInput(light, "TurnOn");
        
        TeleportEntity(light, fPos, NULL_VECTOR, NULL_VECTOR);
        
        return light;
    }
    else
    {
        PrintToServer("Couldn't create light_dynamic!");
    }
    return -1;
}

/**
 * Create Particle
 * 
 * @param char effectName Name of the particle effect you want to spawn.
 *                             Don't forget to precache this OnMapStart!
 * @param float fPos[3] Position to spawn the particle at
 * 
 * @returns entity index for the particle or -1 if no particle was spawned
 */
 
stock int NCRPG_CreateParticle(const char[] effectName, const float fPos[3], const float fAngles[3])
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		TeleportEntity(particle, fPos, fAngles, NULL_VECTOR);
		char tName[128];
		Format(tName, sizeof(tName), "ncrpg_effect_particle_%i", particle);
		DispatchKeyValue(particle, "targetname", tName);
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
        
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");

		return particle;
	}
	else
	{
		PrintToServer("Couldn't create info_particle_system!");
	}
    
	return -1;
}

/**
 * ModifyEntityAttach
 * 
 * http://developer.valvesoftware.com/wiki/Entity_Hierarchy_%28parenting%29
 * 
 * @param entityIndex Entity index of the entity you want to modify
 * @param otherEntityIndex Entity index to attach the particle to
 * @param char attachTo Attachment point of the otherEntityIndex.
 *                           Leave this out or set it to "" when you don't want
 *                           to attach to any specific point.
 */
 
stock void ModifyEntityAttach(const int entityIndex, const int otherEntityIndex, const char[] attachTo="")
{    
    if (IsValidEdict(entityIndex))
    {
        SetVariantString("!activator");
        AcceptEntityInput(entityIndex, "SetParent", otherEntityIndex, entityIndex, 0);
        
        if (!StrEqual(attachTo, ""))
        {
            SetVariantString(attachTo);
            AcceptEntityInput(entityIndex, "SetParentAttachment", entityIndex, entityIndex, 0);
        }
    }
}

/**
 * ModifyEntityAddDeathTimer
 * 
 * @param entityIndex Entity index you want to modify
 * @param float lifetime Seconds after wich the entity should be killed
 */
stock void ModifyEntityAddDeathTimer(const int entityIndex, const float lifetime)
{
    if (IsValidEdict(entityIndex))
    {
        char variantString[60];
        Format(variantString, sizeof(variantString), "OnUser1 !self:Kill::%f:-1", lifetime);
                
        SetVariantString(variantString);
        AcceptEntityInput(entityIndex, "AddOutput");
        AcceptEntityInput(entityIndex, "FireUser1");
    }
}

stock int ThrowAwayParticle(const char[] effectName, const float fPos[3], const float lifetime, const float fAngles[3]=NULL_VECTOR)
{
    int particle = NCRPG_CreateParticle(effectName, fPos, fAngles);
    ModifyEntityAddDeathTimer(particle, lifetime);
    
    return particle;
}
// If you have an attachment point you can pass NULL_VECTOR to fPos
stock int AttachParticleCP(const int client,int client2, const char[] effectName, float fPos[3], const char[] attachTo="", const float fAngles[3]=NULL_VECTOR)
{    
	int particle = NCRPG_CreateParticle(effectName, fPos, fAngles);
	int particle2 = NCRPG_CreateParticle(effectName, fPos, fAngles);
	GetEntPropVector(client2, Prop_Send, "m_vecOrigin", fPos);
	TeleportEntity(particle2, fPos, NULL_VECTOR, NULL_VECTOR);
	char cpName[128];
	Format(cpName, sizeof(cpName), "Xtarget%i", client2);
	DispatchKeyValue(particle2, "targetname", cpName);
	DispatchKeyValue(particle, "cpoint1", cpName);
	ModifyEntityAttach(particle, client, attachTo);
    
	return particle;
}

//Переделать
stock void AttachParticleC2(int ent, char[] particleType,int controlpoint)
{
	int particle  = CreateEntityByName("info_particle_system");
	int particle2 = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3]; 
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		pos[2] = pos[2] + 45.0;  
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);

		GetEntPropVector(controlpoint, Prop_Send, "m_vecOrigin", pos);
		pos[2] = pos[2] + 45.0;  
		TeleportEntity(particle2, pos, NULL_VECTOR, NULL_VECTOR);

		char tName[128];
		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		char cpName[128];
		Format(cpName, sizeof(cpName), "Xtarget%i", controlpoint);

		DispatchKeyValue(particle2, "targetname", cpName);

		DispatchKeyValue(particle, "targetname", "ncrpg_effect_particle_cp_%i");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchKeyValue(particle, "cpoint1", cpName);

		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetVariantString("flag");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);

		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
	}
}  

stock void AttachParticlePlayer(int client, char[] particleType,int client2,float time)
{
	int particle  = CreateEntityByName("info_particle_system");
	int particle2 = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		float pos[3]; 
		//GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
		GetClientAbsOrigin(client,pos);
		pos[2] = pos[2] + 45.0;  
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		GetClientAbsOrigin(client2,pos);
		pos[2] = pos[2] + 45.0;  
		TeleportEntity(particle2, pos, NULL_VECTOR, NULL_VECTOR);
		char tName[128];
		Format(tName, sizeof(tName), "target%i", client);
		DispatchKeyValue(client, "targetname", tName);
		char cpName[128];
		Format(cpName, sizeof(cpName), "Xtarget%i", client2);
		DispatchKeyValue(particle2, "targetname", cpName);
		DispatchKeyValue(particle, "targetname", "ncrpg_effect_particle_cp_%i");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchKeyValue(particle, "cpoint1", cpName);
		DispatchSpawn(particle);
		SetVariantString(tName);
		AcceptEntityInput(particle, "SetParent", client, particle, 0);
		SetVariantString("flag");
		AcceptEntityInput(particle, "SetParentAttachment", particle, particle, 0);
		AcceptEntityInput(particle2, "SetParent", client2, particle2, 0);
		SetVariantString("flag");
		AcceptEntityInput(particle2, "SetParentAttachment", particle2, particle2, 0);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		ModifyEntityAddDeathTimer(particle, time);
		ModifyEntityAddDeathTimer(particle2, time);
	}
}  


// If you have an attachment point you can pass NULL_VECTOR to fPos
stock int AttachParticle(const int client, const char[] effectName, const float fPos[3], const char[] attachTo="", const float fAngles[3]=NULL_VECTOR)
{    
    int particle = NCRPG_CreateParticle(effectName, fPos, fAngles);
    ModifyEntityAttach(particle, client, attachTo);
    
    return particle;
}

// If you have an attachment point you can pass NULL_VECTOR to fPos
stock int AttachThrowAwayParticle(const int client, const char[] effectName, const float fPos[3], const char[] attachTo="", const float lifetime, const float fAngles[3]=NULL_VECTOR)
{    
    int particle = NCRPG_CreateParticle(effectName, fPos, fAngles);
    ModifyEntityAttach(particle, client, attachTo);
    ModifyEntityAddDeathTimer(particle, lifetime);
    
    return particle;
}
/*
// Sounds
stock NCRPG_EmitSoundToClient(client,
				char Path[],entity = SOUND_FROM_PLAYER,channel = SNDCHAN_AUTO,
				level = SNDLEVEL_NORMAL,flags = SND_NOFLAGS,float volume = SNDVOL_NORMAL, 
				pitch = SNDPITCH_NORMAL,speakerentity = -1, const float origin[3] = NULL_VECTOR,
				const float dir[3] = NULL_VECTOR, bool:updatePos = true, float soundtime = 0.0)
{
	if(GameCSGO) Format(Path, sizeof(Path), "*%s", Path);
	EmitSoundToClient(client,Path,entity,channel,level,flags,volume, pitch,speakerentity,origin,dir,updatePos,soundtime);
}*/