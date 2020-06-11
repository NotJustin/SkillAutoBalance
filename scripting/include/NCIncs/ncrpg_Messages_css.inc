//#define MAX_MESSAGE_LENGTH 250
#include<morecolors>

stock bool CommandCheck(char[] compare,char[] commandwanted)
{
	char commandwanted2[70];
	char commandwanted3[70];
	char commandwanted4[70];
	Format(commandwanted2,sizeof(commandwanted2),"\\%s",commandwanted);
	Format(commandwanted3,sizeof(commandwanted3),"/%s",commandwanted);
	Format(commandwanted4,sizeof(commandwanted4),"!%s",commandwanted);
	if(strcmp(compare,commandwanted,false)==0||strcmp(compare,commandwanted2,false)==0||strcmp(compare,commandwanted3,false)==0||strcmp(compare,commandwanted4,false)==0)
	{
		return true;
	}

	return false;
}

stock int CommandCheckEx(char[] compare,char[] commandwanted)
{
  if(StrEqual(commandwanted,"",false))
  {
    return -1;
  }

  char commandwanted2[70];
  char commandwanted3[70];
  Format(commandwanted2,sizeof(commandwanted2),"\\%s",commandwanted);
  Format(commandwanted3,sizeof(commandwanted3),"/%s",commandwanted);
  if(StrContains(compare,commandwanted,false)==0||StrContains(compare,commandwanted2,false)==0||StrContains(compare,commandwanted3,false)==0)
  {
    ReplaceString(compare,70,commandwanted,"",false);
    ReplaceString(compare,70,commandwanted2,"",false);
    ReplaceString(compare,70,commandwanted3,"",false);
    new val=StringToInt(compare);
    if(val>0)
    {
      return val;
    }
  }
  return -1;
}

native void NCRPG_LogMessage(LogType Log,char[] Message,any ...);
native void NCRPG_ChatMessage(int client, const char[] szMessage,any ...);



stock void NCRPG_LogToFile(char[] file,char[] log)
{
	if(!FileExists(file)) CloseHandle(CreateFile(file)); LogToFile(file,log);
}

// Безопасный перевод,  относительно
stock bool FormatST(char[] safe_txt, char[] translate,int maxlen,int TranslateType,char[] phrase, any ...)
{
	if(!TranslationPhraseExists(phrase)) {
		VFormat(translate, maxlen, safe_txt, 6);
		NCRPG_LogMessage(LogType_Error,"Translate phrase %s not found\n Examlple[%s]:",phrase,translate); return false;
	}
	else {
		if(TranslateType <0) TranslateType=Translate_Server;
		SetGlobalTransTarget(TranslateType);
		VFormat(translate,maxlen,"%t",5);
		return true;
	}
}
