/*
 * Регистрация скилла
 *
 * @param shortname Краткое имя скилла.
 * @param maxlevel Максимальный уровень. (по умолчанию)
 * @param cost     цена. (по умолчанию)
 * @param cfg     Будет ли автоматически создан конфиг скилла с переменными maxlevel и cost.
 * @return number skill
 */

 native int NCRPG_RegSkill(const char shortname[MAX_SHORTNAME_LENGTH],int maxlevel,int cost,int icost, bool cfg = true);

/*
 * Поиск скилла по краткому имени
 *
 * @param shortname Краткое имя скилла.
 * @return index скилла
 */


 native int NCRPG_FindSkillByShortname(const char[] shortname);

/*
 * Отключить скилл
 *
 * @param index индекс умения.
 * @param remove true = удалить умение, false = оставить.
 * @no return
 */

 native void NCRPG_DisableSkill(int index, bool remove = false);

/*
 * Получение уровня скилла
 *
 * @param client индекс игрока.
 * @param skillid индекс умения.
 * @return Skill level
 */
 
 native int NCRPG_GetSkillLevel(int client,int skillid);
 
/*
 * Изменение уровня скилла
 *
 * @param client индекс игрока.
 * @param skillid индекс умения.
 * @param level значение.
 * @return Skill level
 */
 
 native int NCRPG_SetSkillLevel(int client,int skillid, int level);
 
/*
 * Вызывается при изменении уровня скилла
 *
 * @param client индекс игрока.
 * @param skillid индекс умения.
 * @param old_value старое значение уровня скилла.
 * @param new_value новое значение уровня скилла.
 *
 */
 
 forward Action NCRPG_OnSkillLevelChange(int client,int &skillid,int old_value,int &new_value);
 
/*
 * Получение кол-ва зарегестрированных скиллов
 *
 * @return Skill Count Кол-во скиллов
 */ 
 
 
 native int NCRPG_GetSkillCount();
 
/*
 * Получение кол-ва не зарегестрированных скиллов
 *
 * @return Skill Count Кол-во скиллов
 */ 
 
 native int NCRPG_GetEmptySkills();
 

/*
 * Проверка валидности скилла
 *
 * @param skillid индекс умения.
 * @param disabled отключено ли умение.
 * @return bool true = скилл валиден false скилл не валиден
 */

 native bool NCRPG_IsValidSkill(int skillid, bool disabled = true); 

 /*
 * Проверка отключен ли скилл
 *
 * @param skillid индекс умения.
 * @return bool true включен false отключен
 */

 native bool NCRPG_IsSkillDisabled(int skillid); 

 /*
 * Получение максимального уровня скилла
 *
 * @param skillid индекс умения.
 * @return level макс. уровень скилла
 */

 native int NCRPG_GetSkillMaxLevel(int skillid); 

 /*
 * Получение полного названия скилла
 *
 * @param skillid индекс умения.
 * @param buffer массив.
 * @param maxlen размер массива.
 * @param client индекс клиента для получения языка перевода (0 = сервер).
 * @return bool true = перевод получен false перевод не получен
 */

 native bool NCRPG_GetSkillName(int skillid, char[] buffer, int maxlen, int client = 0); 
 
  /*
 * Получение цены текущего уровня скилла у клиента
 *
 * @param client индекс клиента.
 * @param skillid индекс умения.
 * @return cost цена умения
 */

 native int NCRPG_GetClientSkillCost(int client, skillid);
  
  /*
 * Получение цены продажи скилла
 *
 * @param skillid индекс скилла.
 * @param level уровень умения.
 * @return cost sale цена продажи умения
 */

 native int NCRPG_GetSkillCostSales(int skillid, int level);
  
  /*
 * Получение цены скилла
 *
 * @param skillid индекс скилла.
 * @param level уровень умения.
 * @return cost умения на level уровне
 */

 native int NCRPG_GetSkillCost(int skillid, int level);
 
  /*
 * Проверка валидности скилла по skillid
 *
 * @param skillid индекс скилла.
 * @return bool true = валиден false = не валиден
 */

 native bool NCRPG_IsValidSkillID(int skillid);
 
  /*
 * Получение полного описания скилла
 *
 * @param skillid индекс скилла.
 * @param buffer буфер перевода.
 * @param maxlen объем буфера.
 * @param client язык перевода.
 * @return bool true = валиден false = не валиден
 */
 
 native bool NCRPG_GetSkillDesc(int skillid, char[] buffer, int maxlen,int client = 0);
 

  /*
 * Необходимо для события Активации скилла
 *
 * @param skillid индекс скилла.
 * @param caller индекс клиента.
 * @param target индекс клиента.
 */
 
 native Action NCRPG_SkillActivate(int skillid,int caller,int target);
 

  /*
 * Необходимо для события окончания активации скилла
 *
 * @param skillid индекс скилла.
 * @param caller индекс клиента.
 */
 
 native void NCRPG_SkillActivated(int skillid,int caller);
 

 
  /*
 * Вызывается перед активации скилла
 *
 * @param skillid индекс скилла.
 * @param caller индекс клиента.
 * @param target индекс клиента.
 */
 
 forward Action NCRPG_OnSkillActivatePre(int skillid,int caller,int target);
 

  /*
 * Вызывается после активации скилла
 *
 * @param skillid индекс скилла.
 * @param caller индекс клиента.
 */
 
 forward NCRPG_OnSkillActivatedPost(int skillid,int caller);

 /*
 * Получение короткого названия скилла
 *
 * @param skillid индекс умения.
 * @param buffer массив.
 * @param maxlen размер массива.
 * @return bool true = короткое имя получено false короткое имя не получено
 */

 native bool NCRPG_GetSkillShortName(int skillid, char[] buffer, int maxlen); 
 