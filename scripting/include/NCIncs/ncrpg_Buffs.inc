/*
 * Вызывается при окончании заморозки
 *
 * @param client индекс игрока.
 */

forward NCRPG_OnFreezeEndPlayer(int client);

/*
 * Вызывается при окончании замедления
 *
 * @param client индекс игрока.
 */

forward NCRPG_OnSlowEndPlayer(int client);

/*
 * Вызывается при замедлении игрока
 *
 * @param client индекс игрока.
 * @param slow сила замедления. (slow<0)
 * @param time время заморозки.
 */

forward Action NCRPG_OnSlowPlayer(int client,float slow,float time);

/*
 * Вызывается при заморозке игрока
 *
 * @param client индекс игрока.
 * @param time время заморозки.
 */

forward Action NCRPG_OnFreezePlayer(int client,float time);

/*
 * Получить максимальное кол-во здоровье игрока
 *
 * @param client индекс игрока.
 * @return max health
 */
 
native int NCRPG_GetMaxHP(int client);

 /*
 * Изменение максимального кол-ва здоровья игрока
 *
 * @param client индекс игрока.
 * @param amount кол-во здоровья.
 * @return max health
 */
 
native int NCRPG_SetMaxHP(int client,int amount);

/*
 * Получить максимальное кол-во брони игрока
 *
 * @param client индекс игрока.
 * @return max armor
 */
 
native int NCRPG_GetMaxArmor(int client);

 /*
 * Изменение максимального кол-ва брони игрока
 *
 * @param client индекс игрока.
 * @param amount кол-во брони.
 * @return max armor
 */
 

native int NCRPG_SetMaxArmor(int client,int amount);

/*
 * Получить максимальную скорость игрока
 *
 * @param client индекс игрока.
 * @return max speed
 */
 
native float NCRPG_GetMaxSpeed(int client);

 /*
 * Изменение максимальной скорости игрока
 *
 * @param client индекс игрока.
 * @param amount значение скорсоти.
 * @return max speed
 */

native float NCRPG_SetMaxSpeed(int client, float amount);

/*
 * Получение текущей скорости игрока
 *
 * @param client индекс игрока.
 * @return speed
 */
 
native float NCRPG_GetSpeed(int client);

 /*
 * Изменение текущей скорости игрока
 *
 * @param client индекс игрока.
 * @param amount значение скорсоти.
 * @return speed
 */

native float NCRPG_SetSpeed(int client, float amount);

 /*
 *  Дописать!
 *
 * @param client индекс игрока.
 * @param amount значение скорсоти.
 * @param time время.
 * @return speed
 */

native Handle NCRPG_SpeedPlayer(int client, float amount, float time);

/*
 * Получение текущей гравитации игрока
 *
 * @param client индекс игрока.
 * @return gravity
 */
 
native float NCRPG_GetGravity(int client);

 /*
 * Изменение текущей гравитации игрока
 *
 * @param client индекс игрока.
 * @param amount значение гравитации.
 * @return gravity
 */

native float NCRPG_SetGravity(int client, float amount);

/*
 * Получение текущего замедления игрока
 *
 * @param client индекс игрока.
 * @return slow
 */
 
native float NCRPG_GetSlow(int client);

 /*
 * Изменение текущего замедления игрока
 *
 * @param client индекс игрока.
 * @param amount сила замедления.
 * @return slow
 */

native float NCRPG_SetSlow(int client, float amount);

 /*
 * Дописать
 *
 * @param client индекс игрока.
 * @param amount сила замедления.
 * @param time время.
 * @return slow
 */
 
native Handle NCRPG_SlowPlayer(int client, float amount, float time);
 
 /*
 * Проверка заморожен ли игрок
 *
 * @param client индекс игрока.
 * @return true or false
 */
 
native bool NCRPG_IsPlayerFrozen(int client);

 /*
 * Изменение заморозки игрока 
 *
 * @param client индекс игрока.
 * @param enable true = заморожен, false разморожен.
 * @return true or false
 */
 
native bool NCRPG_SetIsPlayerFrozen(int client, bool enable);

 /*
 * Заморозить игрока
 *
 * @param client индекс игрока.
 * @param time время замороки.
 * @noreturn
 */
 
native void NCRPG_FreezePlayer(int client, float time);


/*
 * Получить максимальную альфу (невидимость) игрока
 *
 * @param client индекс игрока.
 * @return max alpha
 */
 
native int NCRPG_GetMaxAlpha(int client);

 /*
 * Изменение максимальной альфы (невидимости) игрока
 *
 * @param client индекс игрока.
 * @param amount значение альфы (невидимости). Мин 255, Макс 0
 * @return max alpha
 */

native int NCRPG_SetMaxAlpha(int client,int amount);

/*
 * Получение текущей альфы игрока
 *
 * @param client индекс игрока.
 * @return alpha
 */
 
native int NCRPG_GetAlpha(int client);

 /*
 * Изменение текущей альфы игрока
 *
 * @param client индекс игрока.
 * @param amount значение альфы (невидимости). Мин 255, Макс 0.
 * @return alpha
 */

native int NCRPG_SetAlpha(int client,int amount);

methodmap NCRPG_Buffs
{
	public NCRPG_Buffs(int client)
	{
		return view_as<NCRPG_Buffs>(client);
	}
	property int index
	{

		public get() { return view_as<int>(this); }

	}
	property int MaxAlpha
	{
		public get()
		{
			return NCRPG_GetMaxAlpha(this.index);
		}
		public set(int amount)
		{
			NCRPG_SetMaxAlpha(this.index,amount);
		}
	}
	property int Alpha
	{
		public get()
		{
			return NCRPG_GetAlpha(this.index);
		}
		public set(int amount)
		{
			NCRPG_SetAlpha(this.index,amount);
		}
	}
	property float Gravity
	{
		public get()
		{
			return NCRPG_GetGravity(this.index);
		}
		public set(float amount)
		{
			NCRPG_SetGravity(this.index,amount);
		}
	}
	property float Slow
	{
		public get()
		{
			return NCRPG_GetSlow(this.index);
		}
		public set(float amount)
		{
			NCRPG_SetSlow(this.index,amount);
		}
	}
	property float Speed
	{
		public get()
		{
			return NCRPG_GetSpeed(this.index);
		}
		public set(float amount)
		{
			NCRPG_SetSpeed(this.index,amount);
		}
	}
	property float MaxSpeed
	{
		public get()
		{
			return NCRPG_GetMaxSpeed(this.index);
		}
		public set(float amount)
		{
			NCRPG_SetMaxSpeed(this.index,amount);
		}
	}	
	property int MaxArmor
	{
		public get()
		{
			return NCRPG_GetMaxArmor(this.index);
		}
		public set(int amount)
		{
			NCRPG_SetMaxArmor(this.index,amount);
		}
	}	
	property int MaxHP
	{
		public get()
		{
			return NCRPG_GetMaxHP(this.index);
		}
		public set(int amount)
		{
			NCRPG_SetMaxHP(this.index,amount);
		}
	}
	public bool IsPlayerFrozen()
	{
		return NCRPG_IsPlayerFrozen(this.index);
	}
	public bool SetIsPlayerFrozen(bool amount)
	{
		return NCRPG_SetIsPlayerFrozen(this.index,amount);
	}
	public void FreezePlayer(float amount)
	{
		NCRPG_FreezePlayer(this.index,amount);
	}
	public Handle SlowPlayer(float amount,float time)
	{
		return NCRPG_SlowPlayer(this.index,amount,time);
	}	
	public void HealToMaxHP(int health)
	{
		NCRPG_HealToMaxHP(this.index,health);
	}
};

stock void NCRPG_HealToMaxHP(int client,int health)
{
    int maxhp = NCRPG_GetMaxHP(client);
    int currenthp = GetClientHealth(client);
    if(currenthp < maxhp)
    {
        int newhp = GetClientHealth(client) + health;
        if (newhp > maxhp)
        {
            newhp = maxhp;
        }
        SetEntityHealth(client, newhp);
    }
}

