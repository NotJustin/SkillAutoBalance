StringMap colors;

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