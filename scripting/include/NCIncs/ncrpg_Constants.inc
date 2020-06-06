#define RGBA_COLOR_RED        {255,0,0,4}
#define RGBA_COLOR_GREEN    {0,255,0,3}
#define RGBA_COLOR_BLUE        {0,0,255,3}
#define RGBA_COLOR_YELLOW    {255,255,0,3}
#define RGBA_COLOR_ORANGE    {255,69,0,3}
#define RGBA_COLOR_PURPLE    {128,0,128,3}
#define RGBA_COLOR_CYAN        {255,0,255,3}
#define RGBA_COLOR_WHITE    {255,255,255,3}
#define RGBA_COLOR_BLACK    {0,0,0,3}
#define RGBA_COLOR_GREY        {128,128,128,3}
#define RGBA_COLOR_PINK        {255,20,147,3}
#define RGBA_COLOR_MAROON    {128,0,0,3}
#define RGBA_COLOR_SKYBLUE    {135,206,25,3}
#define RGBA_COLOR_GOLD        {255,215,0,3}
#define RGBA_COLOR_BROWN    {139,69,19,3}
#define RGBA_COLOR_VIOLET    {238,130,238,3}

//#define MAX_MESSAGE_LENGTH 250
#define MAX_STEAMID_LENGTH		32
#define MAX_LEVEL_LENGTH		8
#define MAX_XP_LENGTH			16
#define MAX_CREDITS_LENGTH		16
#define MAX_SHORTNAME_LENGTH	16
#define MAX_SKILL_LENGTH		64
#define MAX_SKILL_DESC			256
#define MAX_RPG_CMDS			32
#define MAX_RPG_CMDS_LENGTH		32
#define MAX_MAPS				64

enum ValveGameEnum
{
  Game_CS=0,
  Game_CSGO=1,
  CS=Game_CS,
  CSGO=Game_CSGO
}

#define CONFIG_CORE  "CORE"
#define CONFIG_NULL  ""
#define CONFIG_SKILL "Skill."
#define CONFIG_ADDON "Addon."
#define CONFIG_TXT ".txt"
#define CONFIG_CFG ".cfg"

enum NCRPG_EventMode
{
	EVENT_NONE=0,
	EVENT_ALL,
	EVENT_PRE,
	EVENT_POST
}

#define MAX_MESSAGE_LENGTH 250
enum LogType
{
	LogType_Normal = 0,
	LogType_Error,
	LogType_FailState,
	LogType_Debug
}

#define Translate_Server LANG_SERVER
