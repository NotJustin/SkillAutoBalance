#if defined _kpr_rating_included
  #endinput
#endif
#define _kpr_rating_included

public SharedPlugin __pl_kpr_rating= 
{
	name = "kpr_rating",
	file = "kpr_rating.smx",
	#if defined REQUIRE_PLUGIN
	required = 1
	#else
	required = 0
	#endif
}

native float KPRRating_GetScore(int client);

public void __pl_kpr_rating_SetNTVOptional()
{
	MarkNativeAsOptional("KPRRating_GetScore");
}