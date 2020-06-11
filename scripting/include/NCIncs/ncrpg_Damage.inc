#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)
#define DMG_VEHICLE			(1 << 4)
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM		(1 << 10)
#define DMG_PREVENT_PHYSICS_FORCE	(1 << 11)
#define DMG_NEVERGIB		(1 << 12)
#define DMG_ALWAYSGIB		(1 << 13)
#define DMG_DROWN			(1 << 14)
#define DMG_TIMEBASED		(DMG_PARALYZE | DMG_NERVEGAS | DMG_POISON | DMG_RADIATION | DMG_DROWNRECOVER | DMG_ACID | DMG_SLOWBURN)
#define DMG_PARALYZE		(1 << 15)
#define DMG_NERVEGAS		(1 << 16)
#define DMG_POISON			(1 << 17)
#define DMG_RADIATION		(1 << 18)
#define DMG_DROWNRECOVER	(1 << 19)
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN		(1 << 21)
#define DMG_REMOVENORAGDOLL	(1 << 22)
#define DMG_PHYSGUN			(1 << 23)
#define DMG_PLASMA			(1 << 24)
#define DMG_AIRBOAT			(1 << 25)
#define DMG_DISSOLVE		(1 << 26)
#define DMG_BLAST_SURFACE	(1 << 27)
#define DMG_DIRECT			(1 << 28)
#define DMG_BUCKSHOT		(1 << 29)

/*
 * Нанесение урона игроку
 *
 * @param victim индекс жертвы.
 * @param damage урон.
 * @param attacker индекс атакующего.
 * @param dmg_type тип урона.
 * @param weapon  оружие.
 * @noreturn
 */
 
stock void NCRPG_DealDamage(int victim,int damage,int attacker = -1,int dmg_type = DMG_GENERIC, char[] weapon = "") {
	if(IsValidPlayer(victim, true) && damage > 0)
	{
		int ent = CreateEntityByName("point_hurt");
		if(ent != -1)
		{
			char buffer[8];
			DispatchKeyValue(victim, "targetname", "ncrpg_hurtme");
			DispatchKeyValue(ent, "DamageTarget", "ncrpg_hurtme");
			
			IntToString(damage, buffer, sizeof(buffer));
			DispatchKeyValue(ent, "Damage", buffer);
			
			IntToString(dmg_type, buffer, sizeof(buffer));
			DispatchKeyValue(ent, "DamageType", buffer);
			
			if(strlen(weapon) > 0)
				DispatchKeyValue(ent, "classname", weapon);
			
			DispatchSpawn(ent);
			AcceptEntityInput(ent, "Hurt", attacker);
			DispatchKeyValue(victim, "targetname", "ncrpg_donthurtme");
			RemoveEdict(ent);
		}
	}
}


stock bool NCRPG_IsDamageFromMelee(const char[] weapon)
{
    switch (NCRPG_GetGame())
    {
        case Game_CS:
        {
            return StrEqual(weapon, "knife");
        }
        case Game_CSGO:
        {
            return (StrContains(weapon,"knife",false) != -1);
        }
    }
    return false;
}
