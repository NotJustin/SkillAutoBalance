#if defined _sab_rating_included
  #endinput
#endif
#define _sab_rating_included

public SharedPlugin __pl_sab_rating= 
{
	name = "sab_rating",
	file = "sab_rating.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
}

native float SABRating_GetScore(int client);

public void __pl_sab_rating_SetNTVOptional()
{
	MarkNativeAsOptional("SABRating_GetScore");
}