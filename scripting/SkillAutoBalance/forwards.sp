GlobalForward
	g_AMTeamSelect,
	g_AMClientSelectFail,
	g_AFKReturnForward,
	g_BalanceCommandForward,
	g_BalanceForward,
	g_ClientInitializedForward,
	g_ClientKickForward,
	g_JoinForward,
	g_JoinTeamForward,
	g_PacifyForward,
	g_SetTeamForward,
	g_SwapForward
;

SABBalanceReason balanceReason;

SABScoreType g_ScoreType;

void CreateForwards()
{
	g_AMTeamSelect = new GlobalForward("SAB_OnAdminMenuTeamSelect", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_AMClientSelectFail = new GlobalForward("SAB_OnAdminMenuClientSelectFail", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_AFKReturnForward = new GlobalForward("SAB_OnClientAFKReturn", ET_Ignore, Param_Cell);
	g_BalanceCommandForward = new GlobalForward("SAB_OnBalanceCommand", ET_Ignore, Param_Cell);
	g_BalanceForward = new GlobalForward("SAB_OnSkillBalance", ET_Ignore, Param_Cell);
	g_ClientInitializedForward = new GlobalForward("SAB_OnClientInitialized", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_ClientKickForward = new GlobalForward("SAB_OnClientKick", ET_Ignore, Param_Cell, Param_Cell);
	g_JoinForward = new GlobalForward("SAB_OnClientJoinCommand", ET_Ignore, Param_Cell, Param_Cell);
	g_JoinTeamForward = new GlobalForward("SAB_OnClientJoinTeam", ET_Ignore, Param_Cell, Param_Cell);
	g_PacifyForward = new GlobalForward("SAB_OnClientPacified", ET_Ignore, Param_Cell);
	g_SetTeamForward = new GlobalForward("SAB_OnSetTeam", ET_Ignore, Param_Cell, Param_Cell);
	g_SwapForward = new GlobalForward("SAB_OnClientTeamChanged", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}